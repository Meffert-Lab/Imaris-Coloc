%Batch Colocalization

%Written by Sreenivas Eadara for the Meffert Lab.
%
%<CustomTools>
%      <Menu>
%       <Submenu name="Surfaces Functions">
%        <Item name="Batch coloc" icon="Matlab">
%          <Command>MatlabXT::XT_BatchColoc(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%      <SurpassTab>
%        <SurpassComponent name="bpSurfaces">
%          <Item name="Batch coloc" icon="Matlab">
%            <Command>MatlabXT::XT_BatchColoc(%i)</Command>
%          </Item>
%        </SurpassComponent>
%      </SurpassTab>
%    </CustomTools>
% 
%Description
%
%This XTension will call XT_Surface_Surface_coloc for all files in a given
%directory. The surfaces to be analyzed are set by the user, who can
%specify either indices or names for each.

function XT_BatchColoc(aImarisApplicationID)
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
%Collect path containing .ims files
directory = string(inputdlg(['Path Containing .ims Files. Omit ' ...
    'trailing slash.']));
if ~isfolder(sprintf('%s%s', directory, filesep))
    msgbox('Not a valid directory!')
    return;
end
if endsWith(directory, filesep)
    msgbox('Omit trailing slash!');
    return;
end

%%
%Determine surface identifier and number of surfaces to analyze
stringOrNum = questdlg('Would you like to define the surfaces by:', ...
    'Select Surface ID Type', 'Surface Name', 'Surface Index', ...
    'Surface Name');
if isempty(stringOrNum)
    msgbox ('You must select an option!');
    return;
end

numSurfaces = str2double(string(inputdlg('Number of surfaces', ...
    'Num Surfaces')));
if isnan(numSurfaces)
    msgbox('Must be a valid number!');
    return;
end
if numSurfaces < 2
    msgbox('Must have at least 2 surfaces!');
    return;
end

%%
%Prompt user to enter identifiers
prompts = strings(numSurfaces, 1);
for a = 1:numSurfaces
    prompts(a, 1) = sprintf('SURFACE %d', a);
end

switch stringOrNum
    case 'Surface Name'
        surfaceIDs = string(inputdlg(prompts, 'Names'));
        doIndices = false;
    case 'Surface Index'
        surfaceIDs = str2double(string(inputdlg(prompts, 'Indices')));
        if sum(isnan(surfaceIDs)) ~= 0
            msgbox('Invalid Input!');
            return;
        end
        doIndices = true;
end

if sum(matches(string(surfaceIDs), '')) ~= 0 || isempty(surfaceIDs)
    msgbox('You must define an identifier for each surface!');
    return;
end

if length(unique(lower(surfaceIDs))) == 1
    msgbox('You must define at least 2 unique IDs!');
    return;
end

%%
%Generate all possible combinations of the surfaces for analysis
if length(surfaceIDs) == 2
    surfaceCombinations = surfaceIDs.';
else
    surfaceCombinations = surfaceIDs(nchoosek(1:length(surfaceIDs), 2));
end

%%
%Call XT_Surface_Surface_coloc for each combination and each file in folder
folderContents = dir (directory);
for i = 1:size(folderContents, 1)
    if endsWith(folderContents(i,1).name, '.ims')
        vImarisApplication.FileOpen(sprintf('%s%s%s', directory, ...
            filesep, folderContents(i,1).name), '');
        for a = 1:size(surfaceCombinations, 1)
            XT_Surface_Surface_coloc(aImarisApplicationID, doIndices, ...
                string(surfaceCombinations(a, 1)), ...
                string(surfaceCombinations(a, 2)));
        end
        vImarisApplication.FileSave(sprintf('%s%s%s', directory, ...
            filesep, folderContents(i,1).name), '');
    end
end

msgbox('DONE');