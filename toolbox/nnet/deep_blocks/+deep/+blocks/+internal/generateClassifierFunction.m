function functionText=generateClassifierFunction(...
    block,...
    networkToLoad,...
    simSupported,...
    inputLayerSize,...
    resizeInput,...
    miniBatchSize,...
    classifyEnabled,...
    predictEnabled,...
    topkEnabled,...
    kValue,...
    labelsTypeName)





    possibleOutputs=["ypred","scores","labels"];
    possibleTempOutputs=["ypredIdx","scores","idxs"];
    outputDependencies=[classifyEnabled,predictEnabled,predictEnabled];

    possibleConversions=[...
    "ypred = "+labelsTypeName+"(ypredIdx);",...
    "labels = "+labelsTypeName+"(idxs);"];
    conversionDependencies=[classifyEnabled,predictEnabled];


    outputs=possibleOutputs(outputDependencies);
    tempOutputs=possibleTempOutputs(outputDependencies);
    conversions=possibleConversions(conversionDependencies);


    outputsString="["+join(outputs,", ")+"]";
    tempOutputsString="["+join(tempOutputs,", ")+"]";


    numOutputs=length(outputs);
    if numOutputs>0
        signature="function "+outputsString+" = classifier(image)";
    else
        signature="function classifier(image)";
    end


    if isempty(inputLayerSize)
        inputLayerSizeString="";
    else
        inputLayerSizeString=join(string(inputLayerSize),", ");
    end
    inputLayerSizeString="["+inputLayerSizeString+"]";


    [useExtrinsicLines,extrinsicVar]=deep.blocks.internal.generateUseExtrinsicCode(simSupported);

    inputsString=join([...
    "image",...
    deep.blocks.internal.removeNewlines("coder.const("""+block+""")"),...
    "'"+networkToLoad+"'",...
    extrinsicVar,...
    inputLayerSizeString,...
    string(resizeInput),...
    miniBatchSize,...
    string(classifyEnabled),...
    string(predictEnabled)...
    ,string(topkEnabled),...
    string(kValue)],", ");
    if numOutputs>0
        call=tempOutputsString+" = deep.blocks.internal.classifier("+inputsString+");";
    else
        call="deep.blocks.internal.classifier("+inputsString+");";
    end


    functionText=join([...
    signature,...
    useExtrinsicLines,...
    call,...
    conversions{:},...
    "end"],newline);

end
