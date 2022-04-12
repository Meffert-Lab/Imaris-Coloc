%
%  Delete Spots Not In Surface
%  Sreenivas Eadara (written for the Meffert Lab)
%
%  Adapted From Spots Split Into Surface Objects Function for Imaris 7.3.0
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
%        <Item name="Delete Spots Not In Surface" icon="Matlab" tooltip="Delete spots not contained in surface">
%          <Command>MatlabXT::XTDeleteSpotsNotInSurface(%i)</Command>
%        </Item>
%         </Submenu>
%      </Menu>
%    </CustomTools>
% 
%
%  Description:
%   
%   For each surfaces object in the same folder of the spots, create a new 
%       surfaces object with only surfaces that contain spots.
%

function XTDeleteSpotsNotInSurface(aImarisApplicationID, varargin)

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

% the user has to create a scene with some spots
vSurpassScene = vImarisApplication.GetSurpassScene;
if isequal(vSurpassScene, [])
  msgbox('Please create some Spots in the Surpass scene!');
  return;
end

% get the spots
vSpots = vImarisApplication.GetFactory.ToSpots(vImarisApplication.GetSurpassSelection);

if ~vImarisApplication.GetFactory.IsSpots(vSpots)  
  msgbox('Please select some Spots!');
  return;
end

spotsToAvoid = [];
if ~isempty(varargin)
    spotsToAvoid = string(varargin);
end


% get the spots coordinates
vSpotsXYZ = vSpots.GetPositionsXYZ;
vSpotsTime = vSpots.GetIndicesT;
vSpotsRadius = vSpots.GetRadiiXYZ;
vSpotsName = char(vSpots.GetName);

vSpots.SetVisible(false);
vTimeInterval = min(vSpotsTime):max(vSpotsTime);
vIndicesSpotsTime = cell(numel(vTimeInterval), 1);
for vTime = vTimeInterval
  vIndicesSpotsTime{vTime - vTimeInterval(1) + 1} = find(vSpotsTime == vTime);
end

% get the parent group
vParentGroup = vSpots.GetParent;

% mask volume
vMin = min(vSpotsXYZ);
vMax = max(vSpotsXYZ);

% add 1% border to be sure to include all spots (avoid edge effects)
vDelta = vMax - vMin;
if ~any(vDelta > 0)
  vDelta = [1, 1, 1];
end
vDelta(vDelta == 0) = mean(vDelta(vDelta > 0));
vMin = vMin - vDelta*0.005;
vMax = vMax + vDelta*0.005;

vMaskSize = 350; 

vMaxMaskSize = vMaskSize / max(vMax-vMin);

% spots coordinates on the mask
vSpotsOnMaskXYZ = zeros(size(vSpotsXYZ));
for vDim = 1:3
  vSpotsOnMaskXYZ(:, vDim) = ceil((vSpotsXYZ(:, vDim)-vMin(vDim))*vMaxMaskSize);
end

% the zeros belongs to the first interval
vSpotsOnMaskXYZ = max(vSpotsOnMaskXYZ, 1); 

vMaskSize = ceil((vMax-vMin)*vMaxMaskSize);

%vProgressDisplay = waitbar(0, 'Identifying surfaces');

% loop over the children of the parent looking for the surfaces
vNumberOfChildren = vParentGroup.GetNumberOfChildren;
for vChildIndex = 1:vNumberOfChildren
  vDataItem = vParentGroup.GetChild(vChildIndex - 1);
  
  if vImarisApplication.GetFactory.IsSurfaces(vDataItem)
    vSurfaces = vImarisApplication.GetFactory.ToSurfaces(vDataItem);
    skip = false;
    if ~isempty(spotsToAvoid)
        for a = 1:size(spotsToAvoid, 2)
            if strncmpi(vSurfaces.GetName, spotsToAvoid(a), 5)
                skip = true;
                break;
            end
        end
    end
    
    if skip
        continue;
    end

    vAllIndices = vSpotsTime;
    vAllIndicesSize = 0;
     
    for vTime = vTimeInterval
        vMask = vSurfaces.GetMask(...
            vMin(1), vMin(2), vMin(3), vMax(1), vMax(2), vMax(3),...
            int32(vMaskSize(1)), int32(vMaskSize(2)), int32(vMaskSize(3)), vTime);

        vMaskImage = vMask.GetDataVolumeAs1DArrayBytes(0, vTime);
        vMaskImage = reshape(vMaskImage, vMaskSize);
        
        % search the element of the spot that lies inside the surface
        vIndexSpotsTime = vIndicesSpotsTime{vTime - vTimeInterval(1) + 1};
        vSpotsCoords = vSpotsOnMaskXYZ(vIndexSpotsTime, :);
        vIndexSpotsInside = vMaskImage(vSpotsCoords(:, 1) + ...
          (vSpotsCoords(:, 2)-1)*vMaskSize(1) + ...
          (vSpotsCoords(:, 3)-1)*vMaskSize(1)*vMaskSize(2)) == 1;
        vIndexSpotsInside = vIndexSpotsTime(vIndexSpotsInside);
        
        vSize = numel(vIndexSpotsInside);
        vAllIndices(vAllIndicesSize + (1:vSize)) = vIndexSpotsInside;
        vAllIndicesSize = vAllIndicesSize + vSize;
    end
    
    vAllIndices = vAllIndices(1:vAllIndicesSize);
    %waitbar(vChildIndex / vNumberOfChildren, vProgressDisplay);
    
    vSpotsInside = vImarisApplication.GetFactory.CreateSpots;
    vSpotsInside.SetVisible(0);
    vSpotsInside.Set(vSpotsXYZ(vAllIndices, :), vSpotsTime(vAllIndices), ...
        zeros(sum(vAllIndices~=0),1));
    vSpotsInside.SetRadiiXYZ(vSpotsRadius(vAllIndices,:));
    vSpotsInside.SetName(sprintf('%s inside %s', ...
        vSpotsName, char(vSurfaces.GetName)));
    vParentGroup.AddChild(vSpotsInside, -1);
  end
end

%close(vProgressDisplay);