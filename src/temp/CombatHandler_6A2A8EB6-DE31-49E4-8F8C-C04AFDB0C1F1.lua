local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");

local Main = require(ReplicatedStorage.Main);
local ModifierHandler = require(ServerScriptService.ServerModules.ModifierHandler);
local EffectsHandler = require(ServerScriptService.ServerModules.EffectsHandler);

local StateHandler = Main.StateHandler;

local CombatHandler = {};

function CombatHandler:rotateCharacter(...)
	local Args = (...);

	local lookAt = Args["lookAt"];
	local Part = Args["Part"];
	local Position = Args["Position"] or nil;
	local relativeToLookAt = Args["relativeToLookAt"] or false;
	local PositionLifetime = Args["PositionLifetime"] or 0.25;
	local RotationLifetime = Args["RotationLifetime"] or 0.25;

	if Position then
		coroutine.wrap(function()
			local BodyPosition = Instance.new("BodyPosition");
			BodyPosition.Position = (relativeToLookAt and (lookAt.CFrame * Position).Position) or Position;	
			BodyPosition.MaxForce = Vector3.new(1, 1, 1) * 1e5;
			BodyPosition.P = 4e4;
			BodyPosition.D = 1000;
			BodyPosition.Parent = Part;

			local t = os.clock();

			repeat task.wait()
				BodyPosition.Position = (relativeToLookAt and (lookAt.CFrame * Position).Position) or Position;	
			until os.clock() - t >= PositionLifetime;

			BodyPosition:Destroy();
		end)()
	end

	local BodyGyro = Instance.new("BodyGyro");
	BodyGyro.D = 5e2;
	BodyGyro.MaxTorque = Vector3.new(0, 4e5, 0);
	BodyGyro.P = 3e4
	BodyGyro.CFrame = CFrame.new(Part.Position, lookAt.Position);
	BodyGyro.Parent = Part;

	task.delay(RotationLifetime, function()
		BodyGyro:Destroy();
	end)
end

function CombatHandler:StartAirCombo(Character, Target, Y)
	local CharacterRootPart = Character.HumanoidRootPart;
	local TargetRootPart = Target.HumanoidRootPart;
	
	local BodyPosition = Instance.new("BodyPosition");
	BodyPosition.MaxForce = Vector3.new(0, 1, 0) * 1e5;
	BodyPosition.P = 4e4;
	BodyPosition.D = 1000;
	BodyPosition.Position = CharacterRootPart.Position + Vector3.new(0, Y, 0);

	local TargetBodyPosition = BodyPosition:Clone();
	TargetBodyPosition.Position = TargetRootPart.Position + Vector3.new(0, -TargetBodyPosition.Position.Y + BodyPosition.Position.Y);
	
	BodyPosition.Parent = CharacterRootPart;
	TargetBodyPosition.Parent = TargetRootPart;

end

function CombatHandler:Knockback(lookVector, Parent, ...)
	local Args = (...);

	local extraVector = Args["extraVector"];
	local Time = Args["Time"];
	local Velocity = Args["Velocity"];

	local knock = Instance.new("BodyVelocity");
	knock.MaxForce = Vector3.new(1, 1, 1) * math.huge --1e4;
	knock.P = 1000;

	if extraVector then
		knock.Velocity = lookVector * Velocity + extraVector;
	else
		knock.Velocity = lookVector * Velocity;
	end

	knock.Parent = Parent;

	task.delay(Time, function()
		knock:Destroy();
	end)
end

function CombatHandler:Guardbreak(Target)
	StateHandler:UpdateState(Target, "isBlocking", false);

	ModifierHandler:Stun(Target, {Stun = 2.5});
end

function CombatHandler:Slowdown(Target, Duration)
	
end

function CombatHandler:ConnectHit(Data)
	local AttackerCharacter = Data.Attacker;
	local AttackData = Data.AttackData;
	local Effects = Data.Effects;
	local HitData = Data.HitData;
	local EnemyHumanoid = HitData.Humanoid;
	local EnemyCharacter = EnemyHumanoid.Parent;

	local isTargetBlocking = StateHandler:GetData(EnemyCharacter, "isBlocking");
	local GuardBreak = AttackData.Guardbreak;
	local BlockBypass = AttackData.BlockBypass;
	local Ragdoll = AttackData.Ragdoll;
	local Stun = AttackData.Stun;
	local Disable = AttackData.Disable;
	local RotateEnemy = AttackData.RotateEnemy;
	local Damage = AttackData.Damage;
	local Knockback = AttackData.Knockback;
	local SelfKnockback = AttackData.SelfKnockback;

	if RotateEnemy then
		RotateEnemy["Part"] = EnemyCharacter.HumanoidRootPart;

		if RotateEnemy["lookAt"] == "CHARACTERROOTPART" then
			RotateEnemy["lookAt"] = AttackerCharacter.HumanoidRootPart;
		end

		CombatHandler:rotateCharacter(RotateEnemy);
	end

	if isTargetBlocking and not GuardBreak and not BlockBypass then
		Damage = 0;
	elseif isTargetBlocking and GuardBreak and not BlockBypass then
		CombatHandler:Guardbreak(EnemyCharacter);
	else
		if Stun then
			print("HI STUNE!!!")
			ModifierHandler:Stun(EnemyCharacter, Stun);
		end
		
		if Disable then
			ModifierHandler:Disable(EnemyCharacter, Disable);
		end
		
		if Knockback then

			local lookVector = AttackerCharacter.HumanoidRootPart.CFrame.LookVector.Unit;

			lookVector = (EnemyCharacter.HumanoidRootPart.CFrame.p - AttackerCharacter.HumanoidRootPart.CFrame.p).Unit;

			CombatHandler:Knockback(lookVector, EnemyCharacter.HumanoidRootPart, Knockback);
		end

		if SelfKnockback then
			local lookVector = AttackerCharacter.HumanoidRootPart.CFrame.LookVector.Unit;

			lookVector = (EnemyCharacter.HumanoidRootPart.CFrame.p - AttackerCharacter.HumanoidRootPart.CFrame.p).Unit;
			CombatHandler:Knockback(lookVector, AttackerCharacter.HumanoidRootPart, SelfKnockback);
		end
	end



	EnemyHumanoid:TakeDamage(Damage);

	EffectsHandler:EffectFunction({
		Effect = "DamageIndicator",
		Args = {
			OriginPart = EnemyCharacter.HumanoidRootPart, Damage = Damage,
		},
	});

end

return CombatHandler;


