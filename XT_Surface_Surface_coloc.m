%Surface surface Colocalization

%Written by Matthew J. Gastinger, Bitplane Advanced Application Scientist.  
%March 2014. Revised by Sreenivas Eadara for the Meffert Lab.
%
%<CustomTools>
%      <Menu>
%       <Submenu name="Surfaces Functions">
%        <Item name="Surface-Surface coloc" icon="Matlab">
%          <Command>MatlabXT::XT_Surface_Surface_coloc(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%      <SurpassTab>
%        <SurpassComponent name="bpSurfaces">
%          <Item name="Surface-Surface coloc" icon="Matlab">
%            <Command>MatlabXT::XT_Surface_Surface_coloc(%i)</Command>
%          </Item>
%        </SurpassComponent>
%      </SurpassTab>
%    </CustomTools>
% 
%Description
%
%This XTension will mask each of 2 surface scenes.  It will find the voxels
%inside each surface that overlap with each other.  A new channel will be
%made, and a new surface generated from the overlapping regions.
%
%REVISION: Now batch processes all files in a folder. The generated
%surface has no smoothing.

function XT_Surface_Surface_coloc(aImarisApplicationID)
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



%%
% the user has to create a scene with some surfaces
aSurpassScene = vImarisApplication.GetSurpassScene();
if isequal(aSurpassScene, [])
    msgbox('Please create some Surfaces in the Surpass scene!');
    return;
end

%Create a new folder object for new surfaces
Coloc_surfaces = vImarisApplication.GetFactory;
result = Coloc_surfaces.CreateDataContainer;
result.SetName('Coloc surfaces');

%clone Dataset
vDataSet = vImarisApplication.GetDataSet.Clone;

%%
% get all Surpass surfaces names
numObjects = aSurpassScene.GetNumberOfChildren();

for a = 1:numObjects
    MAP2Object = aSurpassScene.GetChild(a-1);
    if vImarisApplication.GetFactory.IsSurfaces(MAP2Object) && strcmpi(MAP2Object.GetName(), 'MAP2')
        break;
    end
end
if not(vImarisApplication.GetFactory.IsSurfaces(MAP2Object) && strcmpi(MAP2Object.GetName(), 'MAP2'))
    msgbox('Please create MAP2 surfaces!');
    return;
end
for a = 1:numObjects
    S100Object = aSurpassScene.GetChild(a-1);
    if vImarisApplication.GetFactory.IsSurfaces(S100Object) && strcmpi(S100Object.GetName(), 'S100')
        break;
    end
end
if not(vImarisApplication.GetFactory.IsSurfaces(S100Object) && strcmpi(S100Object.GetName(), 'S100'))
    msgbox('Please create S100 surfaces!');
    return;
end

MAP2Surface = vImarisApplication.GetFactory.ToSurfaces(MAP2Object);
S100Surface = vImarisApplication.GetFactory.ToSurfaces(S100Object);

%%
%Get Image Data parameters
aExtendMaxX = vImarisApplication.GetDataSet.GetExtendMaxX;
aExtendMaxY = vImarisApplication.GetDataSet.GetExtendMaxY;
aExtendMaxZ = vImarisApplication.GetDataSet.GetExtendMaxZ;
aExtendMinX = vImarisApplication.GetDataSet.GetExtendMinX;
aExtendMinY = vImarisApplication.GetDataSet.GetExtendMinY;
aExtendMinZ = vImarisApplication.GetDataSet.GetExtendMinZ;
aSizeX = vImarisApplication.GetDataSet.GetSizeX;
aSizeY = vImarisApplication.GetDataSet.GetSizeY;
aSizeZ = vImarisApplication.GetDataSet.GetSizeZ;
aSizeC = vImarisApplication.GetDataSet.GetSizeC;
aSizeT = vImarisApplication.GetDataSet.GetSizeT;
%Xvoxelspacing= (aExtendMaxX-aExtendMinX)/aSizeX;
vSmoothingFactor=0;

%add additional channel
vDataSet.SetSizeC(aSizeC + 1);
TotalNumberofChannels=aSizeC+1;
vLastChannel=TotalNumberofChannels-1;



%%


%Generate surface mask for each surface over time - currently using
%GetDataVolumeBytes, as other methods suchas 1DArrayBytes were not working
for vTimeIndex= 0:aSizeT-1
    vSurfaces1Mask = MAP2Surface.GetMask(aExtendMinX,aExtendMinY,aExtendMinZ,aExtendMaxX,aExtendMaxY,aExtendMaxZ,aSizeX, aSizeY,aSizeZ,vTimeIndex);
    vSurfaces2Mask = S100Surface.GetMask(aExtendMinX,aExtendMinY,aExtendMinZ,aExtendMaxX,aExtendMaxY,aExtendMaxZ,aSizeX, aSizeY,aSizeZ,vTimeIndex);
    
    ch1 = vSurfaces1Mask.GetDataVolumeAs1DArrayBytes(0,vTimeIndex);
    ch2 = vSurfaces2Mask.GetDataVolumeAs1DArrayBytes(0,vTimeIndex);
    
    %Determine the Voxels that are colocalized
    Coloc=ch1+ch2;
    Coloc(Coloc<2)=0;
    Coloc(Coloc>1)=1;
    
    vDataSet.SetDataVolumeAs1DArrayBytes(Coloc, vLastChannel, vTimeIndex);

end    

vDataSet.SetChannelName(vLastChannel,'ColocChannel');
vDataSet.SetChannelRange(vLastChannel,0,1);

vImarisApplication.SetDataSet(vDataSet);

%Run the Surface Creation Wizard on the new channel
ip = vImarisApplication.GetImageProcessing;
Coloc_surfaces1 = ip.DetectSurfaces(vDataSet, [], vLastChannel, vSmoothingFactor, 0, true, 55, '');
Coloc_surfaces1.SetName(sprintf('ColocSurface'));
Coloc_surfaces1.SetColorRGBA((rand(1, 1)) * 256 * 256 * 256 );

%Add new surface to Surpass Scene
MAP2Surface.SetVisible(0);
S100Surface.SetVisible(0);

result.AddChild(Coloc_surfaces1, -1);
vImarisApplication.GetSurpassScene.AddChild(result, -1);

MAP2stats = MAP2Object.GetStatistics();
S100stats = S100Object.GetStatistics();

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

ColocStats = Coloc_surfaces1.GetStatistics();

ColocStatNames = string(ColocStats.mNames);
ColocVolIndices = find(ColocStatNames == 'Volume');
ColocVolFirst = min(ColocVolIndices);
ColocVolLast = max(ColocVolIndices);
ColocStatValues = ColocStats.mValues;
ColocStatValues = ColocStatValues(ColocVolFirst:ColocVolLast);
ColocVolume = sum(ColocStatValues);

filenameWithPath = string(vImarisApplication.GetCurrentFileName());
if numel(strfind(filenameWithPath, '//')) ~= 0
    filenameWithPath = extractBetween(filenameWithPath, max(strfind(filenameWithPath, "//")) + 1, strlength(filenameWithPath));
end

filename = extractBetween(filenameWithPath, max(strfind(filenameWithPath, "/")) + 1, strlength(filenameWithPath));
directory = extractBetween(filenameWithPath, 1, max(strfind(filenameWithPath, '/')));

surfResultStats = [filename, ColocVolume, MAP2volume, S100volume];

if not(isfile(directory + 'colocResults.csv'))
    ColocResultHeader = ["FILENAME" "VOL COLOC" "VOL MAP2" "VOL S100"];
    writematrix(ColocResultHeader, directory + 'colocResults.csv', 'WriteMode', 'append');
end

writematrix(surfResultStats, directory + 'colocResults.csv', 'WriteMode', 'append');

vImarisApplication.FileSave(directory + filename, '');

folderContents = dir (directory);
folderIMSContents = strings;
for i = 1:size(folderContents)
    if endsWith(folderContents(i,1).name, '.ims')
        folderIMSContents(end + 1) = string(folderContents(i,1).name);
    end
end
folderIMSContents = folderIMSContents(2:end);

currentFileIndex = find(folderIMSContents == filename, 1, "last");
folderSize = numel(folderIMSContents);
if currentFileIndex < folderSize
    nextFile = folderIMSContents(currentFileIndex + 1);
    vImarisApplication.FileOpen(directory + nextFile, '');
    XT_Surface_Surface_coloc(aImarisApplicationID);
end

%vImarisApplication.SetVisible(1);
msgbox('DONE');

