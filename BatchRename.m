%
%  BatchRename
%  Sreenivas Eadara (written for the Meffert Lab)
%  Requires R2021b
%
%  Installation:
%
%  - Copy this file into the XTensions folder in the Imaris installation directory.
%  - You will find this function in the Image Processing menu
%
%    <CustomTools>
%      <Menu>
%         <Submenu name="Surfaces Functions">        
%        <Item name="Batch Rename" icon="Matlab" tooltip="Rename all surfaces created by batch">
%          <Command>MatlabXT::BatchRename(%i)</Command>
%        </Item>
%         </Submenu>
%      </Menu>
%    </CustomTools>
% 
%
%  Description:
%  Rename object created in batch processing.
%

function BatchRename(aImarisApplicationID)

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
    VisibleObject = aSurpassScene.GetChild(a-1);
    VisibleObject.SetVisible(0);
end

ObjectToRename = aSurpassScene.GetChild(numObjects - 1);
ObjectToRename.SetName("ppib");

filenameWithPath = string(vImarisApplication.GetCurrentFileName());
if numel(strfind(filenameWithPath, '//')) ~= 0
    filenameWithPath = extractBetween(filenameWithPath, max(strfind(filenameWithPath, "//")) + 1, strlength(filenameWithPath));
end

filename = extractBetween(filenameWithPath, max(strfind(filenameWithPath, "/")) + 1, strlength(filenameWithPath));

directory = extractBetween(filenameWithPath, 1, max(strfind(filenameWithPath, '/')));
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
    BatchRename(aImarisApplicationID);
end

vImarisApplication.SetVisible(1);
msgbox('DONE');
