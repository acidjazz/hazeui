local component = require("component");
local fs = require("filesystem");
local serialization = require("serialization");
local term = require("term");
local internet = nil;

local packages = {"haze"}
local repositoryURL = "https://raw.githubusercontent.com/acidjazz/hazeui/master/lib/"

local gpu = component.gpu;

function fetchPackage(pack)
	local url = repositoryURL .. pack .. ".lua";

	local request = internet.request(url);
	if request == nil then
		return nil;
	end

	local data = "";

	for chunk in request do
		data = data .. chunk;
	end

	return serialization.unserialize(data);
end


function installPackage(package_data)
	for fileName, fileContents in pairs(package_data.files) do
		local filePath = fs.path(fileName);
		if fs.exists(fileName) then
			fs.remove(fileName);
		end

		if filePath ~= nil then
			local pathSegments = fs.segments(filePath);
			local pathChecked = "/lib/";
			for _, segment in pairs(pathSegments) do
				pathChecked = fs.concat(pathChecked, segment);
				if not fs.exists(pathChecked) then
					fs.makeDirectory(pathChecked);
				end
			end
		end

		local file = io.open(fileName, "wb");
		if file == nil then
			return false;
		end
		file:write(fileContents);
		file:close();
	end

	for linkName, linkTarget in pairs(package_data.links) do
		local filePath = fs.path(fileName);
		if fs.exists(fileName) then
			fs.remove(fileName);
		end

		if filePath ~= nil then
			local pathSegments = fs.segments(filePath);
			local pathChecked = "/";
			for _, segment in pairs(pathSegments) do
				pathChecked = fs.concat(pathChecked, segment);
				if not fs.exists(pathChecked) then
					fs.makeDirectory(pathChecked);
				end
			end
		end

		if not fs.link(linkTarget, linkname) then
			return false;
		end
	end

	return true;
end

print("The following packages are scheduled for deployment:");
local packageNameMaxLen = 0;

if component.isAvailable("internet") then
	internet = component.internet;
else
	print("You need an Internet Card for this to work.");
	return 1;
end

internet = require("internet");

for _, p in pairs(packages) do
	print(" - " .. p);
	packageNameMaxLen = math.max(packageNameMaxLen, string.len(p));
end
print("");

local termWidth = gpu.getResolution();
local _, termY = term.getCursor();
local barWidthMax = termWidth - packageNameMaxLen - 11;

for i, p in pairs(packages) do
	local percent = (2 * (i-1) / #packages / 2);
	local barRep = math.floor(barWidthMax * percent + 0.5);
	term.setCursor(1, termY);
	local pName = string.sub(p .. string.rep(" ", packageNameMaxLen), 1, packageNameMaxLen);

	term.write(pName .. " |" .. string.rep("=", barRep) .. ">" .. string.rep(" ", barWidthMax - barRep) .. "|" .. string.format("%6.2f%%", percent * 100), false);
	local packageData = fetchPackage(p);
	if packageData == nil then
    print(packageData)
		print("");
		print("Failed to download " .. p);
		return;
	end

	term.setCursor(1, termY);
	percent = ((2 * (i-1) + 1) / #packages / 2);
	barRep = math.floor(barWidthMax * percent + 0.5);
	term.write(pName .. " |" .. string.rep("=", barRep) .. ">" .. string.rep(" ", barWidthMax - barRep) .. "|" .. string.format("%6.2f%%", percent * 100), false);

	if not installPackage(packageData) then
		print("");
		print("Failed to install " .. p);
	end
end
term.setCursor(1, termY);
local pName = string.sub("Done" .. string.rep(" ", packageNameMaxLen), 1, packageNameMaxLen);
term.write(pName .. " |" .. string.rep("=", barWidthMax) .. ">" .. "|" .. "100.00%", false);

