export PATH=$PATH:/d/SteamLibrary/SteamApps/common/GarrysMod/bin

gmad create -folder . -out ./stacking_tool.gma
gmpublish update -id 536560898 -addon ./stacking_tool.gma
