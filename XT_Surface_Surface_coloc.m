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

function XT_Surface_Surface_coloc(aImarisApplicationID, varargin)
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
%Detect surfaces present in the Surpass scene
aSurpassScene = vImarisApplication.GetSurpassScene;
numObjects = aSurpassScene.GetNumberOfChildren();

if numObjects == 0
    msgbox('Surpass Scene is empty!');
    return;
end

surfaceObjects = javaArray('Imaris.ISurfacesPrxHelper', numObjects, 1);
surfaceObjectsNames = strings(numObjects, 1);

for a = 1:numObjects
    surpassObject = aSurpassScene.GetChild(a-1);
    if vImarisApplication.GetFactory.IsSurfaces(surpassObject)
        surfaceObjects(a, 1) = ...
            vImarisApplication.GetFactory.ToSurfaces(surpassObject);
        surfaceObjectsNames(a) = surpassObject.GetName();
    end
end

if sum(matches(surfaceObjectsNames, '')) >= length(surfaceObjectsNames) - 1
    msgbox('Please create at least 2 Surfaces in the Surpass Scene!');
    return;
end
surfaceObjects = surfaceObjects(surfaceObjectsNames ~= "");
surfaceObjectsNames = surfaceObjectsNames(surfaceObjectsNames ~= "");

%%
%Allow user to select surfaces to analyze, or take parameters from batch

if isempty(varargin)
    [selectedSurfaceIndex1, tf] = listdlg('PromptString', ...
        'Select First Surface', 'ListString', surfaceObjectsNames, ...
        'SelectionMode', 'single');
    if tf == 0
        msgbox('You must select a surface!');
        return;
    end
    [selectedSurfaceIndex2, tf] = listdlg('PromptString', ...
        'Select Second Surface', 'ListString', surfaceObjectsNames, ...
        'SelectionMode', 'single');
    if tf == 0
        msgbox('You must select a surface!');
        return;
    end
else
    if ~cell2mat(varargin(1))
        selectedSurfaceIndex1 = strfind(lower(surfaceObjectsNames), ...
            lower(cell2mat(varargin(2))));
        selectedSurfaceIndex2 = strfind(lower(surfaceObjectsNames), ...
            lower(cell2mat(varargin(3))));
    
    elseif cell2mat(varargin(1))
        selectedSurfaceIndex1 = str2double(string(varargin(2)));
        selectedSurfaceIndex2 = str2double(string(varargin(3)));
    
    else
        msgbox(sprintf('BATCH ERROR1 %s', ...
            string(vImarisApplication.GetCurrentFileName())))
        return;
    end
end

if selectedSurfaceIndex1 > length(surfaceObjectsNames)
    msgbox(sprintf('BATCH ERROR2 %s', ...
        string(vImarisApplication.GetCurrentFileName())))
    return;
end
if selectedSurfaceIndex2 > length(surfaceObjectsNames)
    msgbox(sprintf('BATCH ERROR3 %s', ...
        string(vImarisApplication.GetCurrentFileName())))
    return;
end

if selectedSurfaceIndex1 == selectedSurfaceIndex2
    msgbox('You must select unique Surfaces!');
    return;
end

MAP2Surface = surfaceObjects(selectedSurfaceIndex1, 1);
MAP2SurfaceName = surfaceObjectsNames(selectedSurfaceIndex1, 1);

S100Surface = surfaceObjects(selectedSurfaceIndex2, 1);
S100SurfaceName = surfaceObjectsNames(selectedSurfaceIndex2, 1);

%%
%Create a new folder object for new surfaces
Coloc_surfaces = vImarisApplication.GetFactory;
result = Coloc_surfaces.CreateDataContainer;
result.SetName(sprintf('%s&%s Surface', MAP2SurfaceName, S100SurfaceName));

%clone Dataset
vDataSet = vImarisApplication.GetDataSet.Clone;

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
    vSurfaces1Mask = MAP2Surface.GetMask(aExtendMinX,aExtendMinY, ...
        aExtendMinZ,aExtendMaxX,aExtendMaxY,aExtendMaxZ,aSizeX, ...
        aSizeY,aSizeZ,vTimeIndex);
    vSurfaces2Mask = S100Surface.GetMask(aExtendMinX,aExtendMinY, ...
        aExtendMinZ,aExtendMaxX,aExtendMaxY,aExtendMaxZ, ...
        aSizeX,aSizeY,aSizeZ,vTimeIndex);
    
    ch1 = vSurfaces1Mask.GetDataVolumeAs1DArrayBytes(0,vTimeIndex);
    ch2 = vSurfaces2Mask.GetDataVolumeAs1DArrayBytes(0,vTimeIndex);
    
    %Determine the Voxels that are colocalized
    Coloc=ch1+ch2;
    Coloc(Coloc<2)=0;
    Coloc(Coloc>1)=1;
    
    vDataSet.SetDataVolumeAs1DArrayBytes(Coloc, vLastChannel, vTimeIndex);
end

vDataSet.SetChannelName(vLastChannel,sprintf('%s &%s Channel', ...
    MAP2SurfaceName, S100SurfaceName));
vDataSet.SetChannelRange(vLastChannel,0,1);

vImarisApplication.SetDataSet(vDataSet);

%Run the Surface Creation Wizard on the new channel
ip = vImarisApplication.GetImageProcessing;
Coloc_surfaces1 = ip.DetectSurfaces(vDataSet, [], vLastChannel, ...
    vSmoothingFactor, 0, false, 0, '');
Coloc_surfaces1.SetName(sprintf('%s &%s Surface', MAP2SurfaceName, ...
    S100SurfaceName));
Coloc_surfaces1.SetColorRGBA((rand(1, 1)) * 256 * 256 * 256 );

%Add new surface to Surpass Scene
MAP2Surface.SetVisible(0);
S100Surface.SetVisible(0);

result.AddChild(Coloc_surfaces1, -1);
vImarisApplication.GetSurpassScene.AddChild(result, -1);
%%
%Retrieve volume data
MAP2stats = MAP2Surface.GetStatistics();
S100stats = S100Surface.GetStatistics();

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

%Find image directory
filenameWithPath = string(vImarisApplication.GetCurrentFileName());

filename = extractBetween(filenameWithPath, ...
    max(strfind(filenameWithPath, filesep)) + 1, strlength(filenameWithPath));
directory = extractBetween(filenameWithPath, 1, ...
    max(strfind(filenameWithPath, filesep)));

if ~isfolder(directory)
    msgbox('Invalid Path! Results not writable.');
    return;
end

%Save results to image directory. Creates a new result file if none exists
surfResultStats = [filename, ColocVolume, MAP2volume, S100volume];
ColocResultHeader = ["FILENAME" "VOL COLOC" ...
    sprintf('VOL %s', MAP2SurfaceName) sprintf('VOL %s', S100SurfaceName)];

writematrix(ColocResultHeader, directory + 'colocResults.csv', ...
    'WriteMode', 'append');
writematrix(surfResultStats, directory + 'colocResults.csv', ...
    'WriteMode', 'append');

if isempty(varargin)
    msgbox('DONE');
end