classdef UaNamespaceBrowser<handle













    properties(Hidden,Access=private,Constant)
        GapX=10;
        GapY=5;
        EdgeX=10;
        EdgeY=10;

        IconPath=fullfile(matlabroot,'toolbox','icomm','opc','opc','+opc','+internal','private');
        IconEnabled=fullfile(fileparts(mfilename('fullpath')),'private','server_tag_normal.gif');
        IconDisabled=fullfile(fileparts(mfilename('fullpath')),'private','server_tag_disabled.gif');


        LoadingString=sprintf('<html>&lt;<i>%s...</i>&gt;</html>',...
        getString(message('opc:NameSpace:LoadingString')));
    end

    properties(Hidden,Access=private)
OKCancelWidth
BtnHeight
AddDelWidth
TxtTreeExtent
TxtListExtent

UIHandles
OPCClient

NamespaceMap

PreviousSelection
ServerSelection
    end

    methods(Hidden,Access=private)
        function this=UaNamespaceBrowser(opcObj,nodeList)



            this.OPCClient=opcObj;


            fqidList={nodeList.FullyQualifiedId};
            this.buildGUI(get(opcObj,'Name'),fqidList);



            this.NamespaceMap=containers.Map();


            this.UIHandles.UITree.UserData.ChildInfo=getNamespace(opcObj);


            this.makeChildren(this.UIHandles.UITree);
        end

        function delete(this)


            if ishandle(this.UIHandles.NameSpaceBrowser)
                delete(this.UIHandles.NameSpaceBrowser);

                this.UIHandles=[];
            end
        end
    end

    methods(Hidden,Access=private)
        function buildGUI(this,clientName,fqidList)

            scrnSize=get(groot,'ScreenSize');

            figSize=min([500,300],scrnSize(3:4)-40);


            figH=uifigure('Units','pixels',...
            'Position',[scrnSize(3)/2-figSize(1)/2,scrnSize(4)/2-figSize(2)/2,figSize],...
            'Resize','on',...
            'WindowStyle','normal',...
            'Name','Browse Name Space',...
            'CloseRequestFcn',@(~,~)this.cancelAction,...
            'Tag','NameSpaceBrowser');


            okButton=uibutton('Parent',figH,...
            "Text",getString(message('opc:NameSpace:OKString')),...
            "ButtonPushedFcn",@(~,~)this.closeRequestHandler,...
            'Tag','BtnOK');%#ok<NASGU>

            cancelButton=uibutton('Parent',figH,...
            'Text',getString(message('opc:NameSpace:CancelString')),...
            'ButtonPushedFcn',@(~,~)this.cancelAction,...
            'Tag','BtnCancel');


            addButton=uibutton('Parent',figH,...
            'Text',getString(message('opc:NameSpace:AddString')),...
            'Tooltip',getString(message('opc:NameSpace:AddTooltipString')),...
            'Tag','BtnAdd',...
            'Enable','off',...
            'ButtonPushedFcn',@(~,~)this.addSelectedToList);%#ok<NASGU>


            addBelowButton=uibutton('Parent',figH,...
            'Text',getString(message('opc:NameSpace:AddBelowString')),...
            'Enable','off',...
            'Tooltip',getString(message('opc:NameSpace:AddBelowTooltipString')),...
            'ButtonPushedFcn',@(~,~)this.addSelectedChildrenToList,...
            'Tag','BtnAddChildren');


            removeButton=uibutton('Parent',figH,...
            'Text',getString(message('opc:NameSpace:RemoveString')),...
            'Enable','off',...
            'Tooltip',getString(message('opc:NameSpace:RemoveTooltipString')),...
            'ButtonPushedFcn',@(~,~)this.removeSelectedFromList,...
            'Tag','BtnRemove');%#ok<NASGU>


            treeTxtH=uilabel('Parent',figH,...
            'Text',getString(message('opc:NameSpace:NamespaceString')),...
            'Tag','TxtTree');
            treeH=uitree('Parent',figH);

            clientNode=uitreenode(treeH,'Text',clientName,'Icon',fullfile(this.IconPath,'opc_server.gif'));%#ok<NASGU>
            figH.UserData=treeH;


            listTxtH=uilabel('Parent',figH,'Text',getString(message('opc:NameSpace:SelectedItemsString')),'Tag','TxtList');
            listH=uilistbox('Parent',figH,'Items',fqidList,'Tag','LstSelected','Multiselect','on');


            this.UIHandles=guihandles(figH);
            this.UIHandles.UITree=treeH;


            ext=get(cancelButton,'OuterPosition');




            this.OKCancelWidth=ext(3)+4*this.GapX;
            this.BtnHeight=ext(4)+this.GapY;
            extAdd=get(addBelowButton,'OuterPosition');

            this.AddDelWidth=extAdd(3)+2*this.GapX;


            this.TxtTreeExtent=get(treeTxtH,'OuterPosition');
            this.TxtListExtent=get(listTxtH,'OuterPosition');
            this.TxtTreeExtent(3:4)=[90,22];
            this.TxtListExtent(3:4)=[90,22];


            listH.BackgroundColor='white';
            listH.ValueChangedFcn=@(~,~)this.listSelectionChanged;
            figH.Resize='on';


            this.UIHandles.UITree.NodeExpandedFcn=@(~,evt)nodeWillExpand(this,evt);
            this.UIHandles.UITree.Multiselect='on';
            this.UIHandles.UITree.SelectionChangedFcn=@(~,e)treeMousePressed(this,e);


            this.resize;
            this.listSelectionChanged;
        end
        function resize(this)
            figPos=get(this.UIHandles.NameSpaceBrowser,'Position');


            minWidth=2*this.EdgeX+2*this.OKCancelWidth+this.AddDelWidth+3*this.GapX+1;
            minHeight=2*this.EdgeY+3*this.BtnHeight+this.TxtTreeExtent(4)+3*this.GapY+1;


            figPos(3:4)=max(figPos(3:4),[minWidth,minHeight]);


            yPos=this.EdgeY;

            this.UIHandles.BtnOK.Position=...
            [figPos(3)-this.EdgeX-this.OKCancelWidth-this.GapX-this.OKCancelWidth,...
            this.EdgeY,...
            this.OKCancelWidth,...
            this.BtnHeight];

            this.UIHandles.BtnCancel.Position=...
            [figPos(3)-this.EdgeX-this.OKCancelWidth,...
            this.EdgeY,...
            this.OKCancelWidth,...
            this.BtnHeight];

            yPos=yPos+this.BtnHeight+this.GapY;
            ltWidth=(figPos(3)-2*this.EdgeX-2*this.GapX-this.AddDelWidth)/2;
            ltHeight=figPos(4)-yPos-this.EdgeY-this.TxtTreeExtent(4);

            this.UIHandles.UITree.Position=...
            [this.EdgeX,...
            yPos,...
            ltWidth,...
            ltHeight];

            this.UIHandles.LstSelected.Position=...
            [figPos(3)-this.EdgeX-ltWidth,...
            yPos,...
            ltWidth,...
            ltHeight];

            this.UIHandles.TxtTree.Position=...
            [this.EdgeX,...
            yPos+ltHeight,...
            this.TxtTreeExtent(3:4)];

            this.UIHandles.TxtList.Position=...
            [figPos(3)-this.EdgeX-ltWidth,...
            yPos+ltHeight,...
            this.TxtListExtent(3:4)];

            yPos=yPos+ltHeight/2-this.GapY/2-this.BtnHeight;

            this.UIHandles.BtnRemove.Position=...
            [this.EdgeX+ltWidth+this.GapX,...
            yPos,...
            this.AddDelWidth,...
            this.BtnHeight];
            yPos=yPos+this.GapY+this.BtnHeight;

            this.UIHandles.BtnAddChildren.Position=...
            [this.EdgeX+ltWidth+this.GapX,...
            yPos,...
            this.AddDelWidth,...
            this.BtnHeight];
            yPos=yPos+this.GapY+this.BtnHeight;

            this.UIHandles.BtnAdd.Position=...
            [this.EdgeX+ltWidth+this.GapX,...
            yPos,...
            this.AddDelWidth,...
            this.BtnHeight];
        end
        function listSelectionChanged(this)

            lstSelectionCount=numel(get(this.UIHandles.LstSelected,'Value'));
            if(lstSelectionCount==1)&&strcmp(get(this.UIHandles.NameSpaceBrowser,'SelectionType'),'open')

                this.removeSelectedFromList;
            end

            this.setAddRemoveButtonState;
        end

        function addSelectedToList(this)

            selectedNodes=this.UIHandles.UITree.SelectedNodes;


            this.ServerSelection={};

            for k=1:numel(selectedNodes)


                if isempty(selectedNodes(k).UserData)
                    continue
                end

                listItem=selectedNodes(k).UserData.ServerInfo.FullyQualifiedId;


                if~ismember(listItem,this.ServerSelection)
                    this.ServerSelection(end+1)={listItem};
                end

                if~ismember(listItem,this.UIHandles.LstSelected.Items)

                    this.UIHandles.LstSelected.Items(end+1)={listItem};

                    this.NamespaceMap(listItem)=selectedNodes(k).UserData.ServerInfo;
                end
            end


            this.UIHandles.UITree.SelectedNodes=[];

            if~isempty(this.ServerSelection)

                this.UIHandles.LstSelected.Value=this.ServerSelection;

                scroll(this.UIHandles.LstSelected,this.UIHandles.LstSelected.Value{1});
            end


            this.setAddRemoveButtonState;
        end

        function addSelectedChildrenToList(this)

            selectedNode=this.UIHandles.UITree.SelectedNodes;



            if isempty(selectedNode.Children)
                return
            end


            if(selectedNode.UserData.ExpandedFlag==0)

                delete(selectedNode.Children);
                makeChildren(this,selectedNode);

                selectedNode.UserData.ExpandedFlag=1;
            end


            expand(selectedNode);


            this.ServerSelection={};


            serverInfo=selectedNode.UserData.ServerInfo;
            this.copyChildren(serverInfo);


            this.UIHandles.LstSelected.Value=this.ServerSelection;


            this.UIHandles.UITree.SelectedNodes=[];


            this.setAddRemoveButtonState;


            scroll(this.UIHandles.LstSelected,this.UIHandles.LstSelected.Value{end});
        end

        function removeSelectedFromList(this)

            selectedServerIdx=find(ismember(this.UIHandles.LstSelected.Items,this.UIHandles.LstSelected.Value)==1);
            selectedSignals=this.UIHandles.LstSelected.Items(selectedServerIdx);


            this.UIHandles.LstSelected.Items=setdiff(this.UIHandles.LstSelected.Items,selectedSignals,'stable');


            if~isempty(this.UIHandles.LstSelected.Items)
                pos=max(selectedServerIdx)-numel(selectedServerIdx);
                if(pos==0)
                    pos=1;
                end
                this.UIHandles.LstSelected.Value=this.UIHandles.LstSelected.Items(pos);
            end


            this.setAddRemoveButtonState;
        end

        function closeRequestHandler(this)


            uiresume(this.UIHandles.NameSpaceBrowser);
        end

        function cancelAction(this)

            set(this.UIHandles.LstSelected,...
            'Items',{},...
            'Value',{});
            this.closeRequestHandler;
        end

        function setAddRemoveButtonState(this)

            addCount=numel(this.UIHandles.UITree.SelectedNodes);


            if addCount>0
                set(this.UIHandles.BtnAdd,'Enable','on');
            else
                set(this.UIHandles.BtnAdd,'Enable','off');
            end


            if(addCount==1)
                set(this.UIHandles.BtnAddChildren,'Enable','on');
            else
                set(this.UIHandles.BtnAddChildren,'Enable','off');
            end


            removeCount=numel(get(this.UIHandles.LstSelected,'Value'));
            if removeCount>0
                set(this.UIHandles.BtnRemove,'Enable','on');
            else
                set(this.UIHandles.BtnRemove,'Enable','off');
            end

        end
    end

    methods(Hidden,Access=private)
        function makeChildren(this,treeNode)


            nsChildren=treeNode.UserData.ChildInfo;

            for iteration=1:length(nsChildren)

                child=uitreenode(treeNode,'Text',nsChildren(iteration).Name,'Icon',this.IconEnabled);
                child.UserData.ServerInfo=nsChildren(iteration);

                if isempty(nsChildren(iteration).Children)
                    continue;
                end



                child.UserData.ChildInfo=nsChildren(iteration).Children;
                child.UserData.ExpandedFlag=0;

                uitreenode(child,'Text','','Icon',this.IconEnabled);
            end

        end

        function copyChildren(this,serverInfo)

            for idx=1:length(serverInfo.Children)
                serverChild=serverInfo.Children(idx);


                listItem=serverChild.FullyQualifiedId;



                if~ismember(listItem,this.ServerSelection)
                    this.ServerSelection(end+1)={listItem};
                end


                if~ismember(listItem,this.UIHandles.LstSelected.Items)

                    this.UIHandles.LstSelected.Items(end+1)={listItem};

                    this.NamespaceMap(listItem)=serverChild;
                end


                if isempty(serverChild.Children)
                    continue;
                end


                this.copyChildren(serverChild);
            end

        end

        function nodeWillExpand(this,eventData)

            eNode=eventData.Node;



            if(eNode.UserData.ExpandedFlag==1)
                return
            end


            delete(eNode.Children)
            makeChildren(this,eNode);
        end
        function treeMousePressed(this,~)
            selNodes=get(this.UIHandles.UITree,'SelectedNodes');


            if strcmpi(get(this.UIHandles.NameSpaceBrowser,'SelectionType'),'open')

                if(length(selNodes)==1)&&isempty(selNodes(1).Children)


                    this.addSelectedToList;
                end
            end
            this.setAddRemoveButtonState;
        end
    end

    methods(Static)
        function nodeList=create(opcObj,nodeList)

            narginchk(2,2);
            nsObj=opc.internal.UaNamespaceBrowser(opcObj,nodeList);
            uiwait(nsObj.UIHandles.NameSpaceBrowser);


            fqidList=get(nsObj.UIHandles.LstSelected,'Items');
            if isempty(fqidList)
                nodeList=opc.ua.Node.empty;
            else
                itmCell=values(nsObj.NamespaceMap,fqidList);
                nodeList=[itmCell{:}];
            end
            delete(nsObj);
        end
    end
end
