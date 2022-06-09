local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local ServerMain = require(ServerScriptService.ServerMain);
local Main = require(ReplicatedStorage.Main);
local ComboHandler = require(ReplicatedStorage.Modules.ComboHandler);

local SpeedHandler = require(ServerScriptService.ServerModules.SpeedHandler);
local CombatHandler = ServerMain.CombatHandler;
local HitboxHandler = ServerMain.HitboxHandler;
local StateHandler = Main.StateHandler;
local CooldownHandler = Main.CooldownHandler;

local Light = {};
Light.CustomCooldown = true;
Light.Active = false;

function Light:Execute(Player, ClientData, Data)
	local Character = Player.Character;
	local RootPart = Character.HumanoidRootPart;
	local Humanoid = Character.Humanoid;
	
	local Combo = ComboHandler:DoM1(Player, Data.SpaceHeld);
	local SequenceType = ComboHandler:GetM1Type(Player);
	
	SpeedHandler:ChangeSpeed(Character, "default", 0);
	
	print(SequenceType);
	task.wait(if Combo == "00000" then 0.12 else 0.12);
	
	local Hitbox = HitboxHandler.new({
		Attacker = Character,
		Framerate = 60,
		ExtraData = {
			Debug = true,
		},
		Size = Vector3.new(6, 6, 6),
		Offset = Vector3.new(0, 0, -3),
		Part = RootPart,
	});
	
	Hitbox.OnHit:Connect(function(HitData)
		if Combo == "0001" or Combo == "01" or Combo == "1" then
			print("lol AIR COMBO!!!");
			CombatHandler:StartAirCombo(Character, HitData.Humanoid.Parent, 10);
		end
		
		CombatHandler:ConnectHit({
			AttackData = ClientData.AttackData,
			Attacker = Character,
			Effects = {"LightHit"},
			HitData = HitData,
		});
	end)
	
	Hitbox:StartOnce();
	
	local OldTime = StateHandler:GetData(Character, "lastClickCombo");
	
	task.delay(1.3, function()
		if OldTime == StateHandler:GetData(Character, "lastClickCombo") then
			SpeedHandler:ChangeSpeed(Character, "default", "default");
		end
	end)

	if #Combo == 5 then
		CooldownHandler:UpdateCooldown(Character, "Light", {
			Lifetime = ClientData.FinalCooldown
		});
	else
		CooldownHandler:UpdateCooldown(Character, "Light", {
			Lifetime = ClientData.Cooldown
		});
	end
end

function Light:Cancel()

end

function Light:CleanUp()

end

return Light;


