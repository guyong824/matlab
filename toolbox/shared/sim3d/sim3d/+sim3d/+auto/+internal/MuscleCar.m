classdef MuscleCar




    properties(Constant=true)
        FrontBumper=struct(...
        'translation',single([2.4735,0,0.44]),...
        'rotation',single([0,0,0]),...
        'scale',single([1,1,1]));
        RearBumper=struct(...
        'translation',single([-2.4735,0,0.44]),...
        'rotation',single([0,0,pi]),...
        'scale',single([1,1,1]));
        RightMirror=struct(...
        'translation',single([0.43,1.08,1.0]),...
        'rotation',single([0,-pi/2,0]),...
        'scale',single([1,1,1]));
        LeftMirror=struct(...
        'translation',single([0.43,-1.08,1.0]),...
        'rotation',single([0,-pi/2,0]),...
        'scale',single([1,1,1]));
        RearviewMirror=struct(...
        'translation',single([0.32,0,1.19]),...
        'rotation',single([0,0,0]),...
        'scale',single([1,1,1]));
        HoodCenter=struct(...
        'translation',single([1.2760,0,1.13]),...
        'rotation',single([0,0,0]),...
        'scale',single([1,1,1]));
        RoofCenter=struct(...
        'translation',single([-0.25,0,1.57]),...
        'rotation',single([0,0,0]),...
        'scale',single([1,1,1]));
    end

end