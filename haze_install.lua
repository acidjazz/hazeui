local component = require("component");
local fs = require("filesystem");
local term = require("term");
local internet = nil;

local packages = {"hazeui"}
--local repositoryURL = "http://50.0.80.248:1337/lib/"
local repositoryURL = "https://raw.githubusercontent.com/acidjazz/hazeui/master/lib/"

local gpu = component.gpu;

function fetchPackage(pack)
	local url = repositoryURL .. pack .. ".lua";

	local request = internet.request(url);
  print(request)
	if request == nil then
		return nil;
	end

	local data = "";

	for chunk in request do
		data = data .. chunk;
	end

	--return serialization.unserialize(data);
  return data;
end


function installPackage(file, contents)

		local file = io.open("/lib/" .. file .. ".lua", "wb");

		if file == nil then
			return false;
		end

		file:write(contents);
		file:close();

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

	if not installPackage(p, packageData) then
		print("");
		print("Failed to install " .. p);
	end
end
term.setCursor(1, termY);
local pName = string.sub("Done" .. string.rep(" ", packageNameMaxLen), 1, packageNameMaxLen);
term.write(pName .. " |" .. string.rep("=", barWidthMax) .. ">" .. "|" .. "100.00%", false);

