function BatchColoc(aImarisApplicationID)
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

directory = string(inputdlg('Path Containing .ims Files. Omit trailing slash.'));
if ~isfolder(sprintf('%s/', directory))
    msgbox('Not a valid directory!')
    return;
end
if endsWith(directory, '/')
    msgbox('Omit trailing slash!');
    return;
end

stringOrNum = questdlg('Would you like to define the surfaces by:', 'Select Surface ID Type', 'Surface Name', 'Surface Index', 'Surface Name');
if isempty(stringOrNum)
    msgbox ('You must select an option!');
    return;
end

numSurfaces = str2double(string(inputdlg('Number of surfaces to analyze', 'Num Surfaces')));
if isnan(numSurfaces)
    msgbox('Must be a valid number!');
    return;
end
if numSurfaces < 1
    msgbox('Must have > 0 surfaces!');
    return;
end

prompts = strings(numSurfaces, 1);
for a = 1:numSurfaces
    prompts(a, 1) = sprintf('SURFACE %d', a);
end

switch stringOrNum
    case 'Surface Name'
        surfaceIDs = string(inputdlg(prompts, 'Surface Names'));
    case 'Surface Index'
        surfaceIDs = str2double(string(inputdlg(prompts, 'Surface Indices')));
        if sum(isnan(surfaceIDs)) ~= 0
            msgbox('Invalid Input!');
            return;
        end
end

if sum(matches(string(surfaceIDs), '')) ~= 0
    msgbox('You must define an identifier for each surface!');
    return;
end

surfaceCombinations = surfaceIDs(nchoosek(1:length(surfaceIDs), 2));

folderContents = dir (directory);
for i = 1:size(folderContents)
    if endsWith(folderContents(i,1).name, '.ims')
        vImarisApplication.FileOpen(sprintf('%s/%s', directory, folderContents(i,1).name), '');
        for a = 1:length(surfaceCombinations)
            XT_Surface_Surface_coloc(aImarisApplicationID, string(surfaceCombinations(a, 1)), string(surfaceCombinations(a, 2)));
        end
        vImarisApplication.FileSave(sprintf('%s/%s', directory, folderContents(i,1).name), '');
    end
end