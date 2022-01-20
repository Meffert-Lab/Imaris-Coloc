%
%  Lin28Util
%  Sreenivas Eadara (written for the Meffert Lab)
%
%
%  Installation:
%
%  - Copy this file into the XTensions folder in the Imaris installation directory.
%  - You will find this function in the Image Processing menu
%
%    <CustomTools>
%      <Menu>
%         <Submenu name="Spots Functions">        
%        <Item name="Lin28 Utility" icon="Matlab" tooltip="Run all Lin28 processing steps">
%          <Command>MatlabXT::Lin28Util(%i)</Command>
%        </Item>
%         </Submenu>
%      </Menu>
%    </CustomTools>
% 
%
%  Description:
%  Perform selection for Lin28 inside MAP2 and S100 followed by cleaning of
%  S100 and then filtering of Lin28 surfaces.
%

function Lin28Util(aImarisApplicationID)

% connect to Imaris interface
if ~isa(aImarisApplicationID, 'Imaris.IApplicationPrxHelper')
  javaaddpath ImarisLib.jar
  vImarisLib = ImarisLib;
  if ischar(aImarisApplicationID)
    aImarisApplicationID = round(str2double(aImarisApplicationID));
  end
  vImarisApplication = vImarisLib.GetApplication(aImarisApplicationID);
else
  vImarisApplication = aImarisApplicationID;
end

aSurpassScene = vImarisApplication.GetSurpassScene();
numObjects = aSurpassScene.GetNumberOfChildren();
for a = 1:numObjects
    Lin28Object = aSurpassScene.GetChild(a-1);
    if vImarisApplication.GetFactory.IsSpots(Lin28Object) && strcmpi(Lin28Object.GetName(), 'Lin28')
        break;
    end
end
if not(vImarisApplication.GetFactory.IsSpots(Lin28Object))
    msgbox('Please create Lin28 spots!');
    return;
end
for a = 1:numObjects
    Lin28SurfaceObject = aSurpassScene.GetChild(a-1);
    if vImarisApplication.GetFactory.IsSurfaces(Lin28SurfaceObject) && strcmpi(Lin28SurfaceObject.GetName(), 'Lin28')
        break;
    end
end
if not(vImarisApplication.GetFactory.IsSurfaces(Lin28SurfaceObject))
    msgbox('Please create Lin28 surfaces!');
    return;
end
for a = 1:numObjects
    MAP2Object = aSurpassScene.GetChild(a-1);
    if vImarisApplication.GetFactory.IsSurfaces(MAP2Object) && strcmpi(MAP2Object.GetName(), 'MAP2')
        break;
    end
end
if not(vImarisApplication.GetFactory.IsSurfaces(MAP2Object))
    msgbox('Please create MAP2 surfaces!');
    return;
end
for a = 1:numObjects
    S100Object = aSurpassScene.GetChild(a-1);
    if vImarisApplication.GetFactory.IsSurfaces(S100Object) && strcmpi(S100Object.GetName(), 'S100')
        break;
    end
end
if not(vImarisApplication.GetFactory.IsSurfaces(S100Object))
    msgbox('Please create S100 surfaces!');
    return;
end

vImarisApplication.SetSurpassSelection(Lin28Object);

XTDeleteSpotsNotInSurface(aImarisApplicationID);
S100Cleaner(aImarisApplicationID);

numObjects = aSurpassScene.GetNumberOfChildren();
SpotObject1 = vImarisApplication.GetSurpassScene.GetChild(numObjects - 2);
SpotObject2 = vImarisApplication.GetSurpassScene.GetChild(numObjects - 1);

if endsWith(SpotObject1.GetName(), 'MAP2')
    MAP2SpotsObject = SpotObject1;
    S100SpotsObject = SpotObject2;
else
    S100SpotsObject = SpotObject1;
    MAP2SpotsObject = SpotObject2;
end
MAP2Spots = vImarisApplication.GetFactory.ToSpots(MAP2SpotsObject);
S100Spots = vImarisApplication.GetFactory.ToSpots(S100SpotsObject);

aSurpassScene = vImarisApplication.GetSurpassScene();
numObjects = aSurpassScene.GetNumberOfChildren();

vImarisApplication.SetSurpassSelection(vImarisApplication.GetSurpassScene.GetChild(numObjects - 2));
XTDeleteSurfacesNotContainingSpot(aImarisApplicationID);

vImarisApplication.SetSurpassSelection(vImarisApplication.GetSurpassScene.GetChild(numObjects - 1));
XTDeleteSurfacesNotContainingSpot(aImarisApplicationID);

numObjects = aSurpassScene.GetNumberOfChildren();
SurfaceObject1 = vImarisApplication.GetSurpassScene.GetChild(numObjects - 2);
SurfaceObject2 = vImarisApplication.GetSurpassScene.GetChild(numObjects - 1);

if endsWith (SurfaceObject1.GetName(), 'MAP2')
    MAP2SurfaceObject = SurfaceObject1;
    S100SurfaceObject = SurfaceObject2;
else
    S100SurfaceObject = SurfaceObject1;
    MAP2SurfaceObject = SurfaceObject2;
end

filename = string(vImarisApplication.GetCurrentFileName());

Lin28Surfacesstats = Lin28SurfaceObject.GetStatistics();
MAP2SurfacesLin28stats = MAP2SurfaceObject.GetStatistics();
S100SurfacesLin28stats = S100SurfaceObject.GetStatistics();
MAP2stats = MAP2Object.GetStatistics();
S100stats = S100Object.GetStatistics();

Lin28SurStatNames = string(Lin28Surfacesstats.mNames);
Lin28SurVolIndices = find(Lin28SurStatNames == 'Volume');
Lin28SurVolFirst = min(Lin28SurVolIndices);
Lin28SurVolLast = max(Lin28SurVolIndices);
Lin28SurStatValues = Lin28Surfacesstats.mValues;
Lin28SurStatValues = Lin28SurStatValues(Lin28SurVolFirst:Lin28SurVolLast);
Lin28SurStat = sum(Lin28SurStatValues);

MAP2SurStatNames = string(MAP2SurfacesLin28stats.mNames);
MAP2SurVolIndices = find(MAP2SurStatNames == 'Volume');
MAP2SurVolFirst = min(MAP2SurVolIndices);
MAP2SurVolLast = max(MAP2SurVolIndices);
MAP2SurStatValues = MAP2SurfacesLin28stats.mValues;
MAP2SurStatValues = MAP2SurStatValues(MAP2SurVolFirst:MAP2SurVolLast);
MAP2Lin28SurStat = sum(MAP2SurStatValues);

S100SurStatNames = string(S100SurfacesLin28stats.mNames);
S100SurVolIndices = find(S100SurStatNames == 'Volume');
S100SurVolFirst = min(S100SurVolIndices);
S100SurVolLast = max(S100SurVolIndices);
S100SurStatValues = S100SurfacesLin28stats.mValues;
S100SurStatValues = S100SurStatValues(S100SurVolFirst:S100SurVolLast);
S100Lin28SurStat = sum(S100SurStatValues);

MAP2StatNames = string(MAP2stats.mNames);
MAP2VolIndices = find(MAP2StatNames == 'Volume');
MAP2VolFirst = min(MAP2VolIndices);
MAP2VolLast = max(MAP2VolIndices);
MAP2StatValues = MAP2stats.mValues;
MAP2StatValues = MAP2StatValues(MAP2VolFirst:MAP2VolLast);
MAP2volume = sum(MAP2StatValues);

S100StatNames = string(S100stats.mNames);
S100VolIndices = find(S100StatNames == 'Volume');
S100VolFirst = min(S100VolIndices);
S100VolLast = max(S100VolIndices);
S100StatValues = S100stats.mValues;
S100StatValues = S100StatValues(S100VolFirst:S100VolLast);
S100volume = sum(S100StatValues);

Lin28Spots = vImarisApplication.GetFactory.ToSpots(Lin28Object);
spotResultStats = [filename, numel(Lin28Spots.GetIds), numel(MAP2Spots.GetIds), numel(S100Spots.GetIds)];
surfResultStats = [filename, Lin28SurStat, MAP2Lin28SurStat, S100Lin28SurStat];
normSpotResultStats = [filename, numel(MAP2Spots.GetIds) / MAP2volume, numel(S100Spots.GetIds) / S100volume];
normSurfResultStats = [filename, MAP2Lin28SurStat / MAP2volume, S100Lin28SurStat / S100volume];

directory = extractBetween(filename, 1, max(strfind(filename, '/')));

if not(isfile(directory + 'spotResults.csv'))
    SpotResultHeader = ['FILENAME', 'N TOTAL', 'N MAP2', 'N S100'];
    writematrix(SpotResultHeader, directory + 'spotResults.csv', 'WriteMode', 'append');
end
if not(isfile(directory + 'surfResults.csv'))
    SurfResultHeader = ['FILENAME', 'VOL TOTAL', 'VOL MAP2', 'VOL S100'];
    writematrix(SurfResultHeader, directory + 'surfResults.csv', 'WriteMode', 'append');
end
if not(isfile(directory + 'normSpotResults.csv'))
    NormSpotResultHeader = ['FILENAME', 'N MAP2 NORM', 'N S100 NORM'];
    writematrix(NormSpotResultHeader, directory + 'normSpotResults.csv', 'WriteMode', 'append');
end
if not(isfile(directory + 'normSurfResults.csv'))
    NormSurfResultHeader = ['FILENAME', 'VOL MAP2 NORM', 'VOL S100 NORM'];
    writematrix(NormSurfResultHeader, directory + 'normSurfResults.csv', 'WriteMode', 'append');
end

writematrix(spotResultStats, directory + 'spotResults.csv', 'WriteMode', 'append');
writematrix(surfResultStats, directory + 'surfResults.csv', 'WriteMode', 'append');
writematrix(normSpotResultStats, directory + 'normSpotResults.csv', 'WriteMode', 'append');
writematrix(normSurfResultStats, directory + 'normSurfResults.csv', 'WriteMode', 'append');

vImarisApplication.FileSave(directory + filename, '');

folderContents = dir (directory);
folderContentsNames = folderContents(:,:).name;
folderIMSContents = folderContentsNames(endsWith(string(folderContentsNames), '.ims'));

currentFileIndex = find(folderIMSContents == filename, 1, "last");
folderSize = numel(folderIMSContents);
if currentFileIndex < folderSize
    nextFile = folderIMSContents(currentFileIndex + 1);
    vImarisApplication.FileOpen(directory + nextFile);
    Lin28Util(aImarisApplicationID);
end

msgbox('DONE');
