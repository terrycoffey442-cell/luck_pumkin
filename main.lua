--[[
    Pet Simulator 99 - Pumpkin Patch Tycoon! Kaitun Core
    Target: Fast full automation (Buttons Rush Part 1 & 2, Smart Farm, Keep/Lock/Stock, Merchant, Upgrades, Boosts Tier 1-3 / Cocoa, Gifts, Zone 8 Egg Hatch, Anti-AFK, Pet Speed, Map & Render Optimizer)
]]

-- ============================================================================
-- 0. USER CONFIGURATION (Set getgenv().Config before loadstring, or edit here)
-- ============================================================================
getgenv().Config = getgenv().Config or {
    Enabled = true,
    Debug = true,

    -- Progression (Part 1 + Part 2)
    RushButtonsFirst = true,          -- Hold Coins for Buttons + Completion before Hatch/Merchant
    AutoCompletePart2 = true,         -- Claim Part 2 completion (MH_Conclude) at 117/117
    BuyOptionalPart2Buttons = false,  -- Optional Zone 8 Cannon & Rebirth Shrine after 117/117
    TargetRebirths = 0,               -- 0 = Off | 3 = max 1.0x egg odds | 20 = max +400% Coins | -1 = infinite

    -- Hatching & Crafting
    AutoHatch = true,
    TargetEggName = "Golden Ridge Egg", -- Zone 8 egg (auto-falls back to highest unlocked egg)
    AutoMakeGold = true,
    AutoMakeRainbow = true,

    -- Economy, Gifts & Pedestals
    AutoOpenGifts = true,
    AutoConsumeBoosts = true,         -- Auto use Patch Coin / Pumpkin Damage / Island Luck Boost consumables
    AutoUpgrades = true,
    AutoCocoaStand = true,
    AutoBuyMerchant = true,           -- Auto buy Merchant Mythical+/Exotic+/Legendary+ (<= 5% Coins in Part 2 Rush)
    KeepRung = 0,                     -- 0 = Auto Part 2 EarnRate Lock (Zone 6+) | 2=Rare .. 8=Secret manual override

    -- Wild Hunt, Turkey Boss & Pet Net Store (Part 2)
    AutoTurkeyBoss = true,            -- Auto fight server-wide Turkey Boss (TurkeyArena) until dead for Nets + Boss Sighting
    AutoHuntWild = true,              -- Scan entire island & catch wild pets (RU_Ensnare, 3s)
    AutoCatchSighting = true,         -- Auto catch Boss Turkey Sightings (PV_Glimpse)
    HuntMinTier = 4,                  -- 0=Any | 1=Uncommon+ | 2=Rare+ | 3=Epic+ | 4=Huges only
    HuntVariantsOnly = false,         -- true = only catch Golden/Rainbow/Shiny
    AutoBuyNetStore = true,           -- Auto buy Net Store (always buys Ultra Net; buys Pet Net post-buttons or <= 5% Coins in Rush)

    -- Performance & UI
    ShowKaitunUI = true,              -- Full-screen black dashboard overlay + 3D rendering off
    OptimizeMap = true,
    UltraLowRAM = false,

    -- Discord Pet Drop Webhook (Huge / Titanic / Gargantuan)
    WebhookEnabled = true,
    WebhookUrl = "",                  -- Personal Discord Webhook URL
}

-- ============================================================================
-- 1. RE-EXECUTION TEARDOWN GUARD
-- ============================================================================
local GEN_KEY = "_PumpkinTycoonKaitun"
local prevEnv = getgenv()[GEN_KEY]
if type(prevEnv) == "table" and type(prevEnv.Teardown) == "function" then
    pcall(prevEnv.Teardown)
    task.wait(0.15)
end

-- ============================================================================
-- 1B. INTERNAL DEFAULT CONFIGURATION (All keys can be overridden via getgenv().Config)
-- ============================================================================
local DEFAULT_CONFIG = {
    Enabled = true,
    Debug = true,

    -- Instance & Onboarding
    AutoJoin = true,
    AutoTutorial = true,

    -- Anti-AFK (Roblox 20m + PS99 Idle Tracking)
    AntiAFK = true,
    AntiAfkMode = "auto",           -- "auto" ("safe" on Mobile/Delta or when Idle Tracking disables cleanly), "safe", "hook"
    AntiAFKRoblox = true,           -- Periodic VirtualUser pulse (< 120s) + LocalPlayer.Idled fallback against 20m kick
    AntiAFKRobloxPulseInterval = 45,-- Seconds between proactive VirtualUser & Idle Tracking reset pulses
    AntiAFKP99 = true,              -- Disables PS99 Scripts.Core["Idle Tracking"] + resets server idle timer
    AntiAFKP99PulseInterval = 6.5,  -- Seconds between desktop F15 pulses when hook fallback is active
    BlockNativeMoveServer = true,   -- Suppress "Move Server", "Idle Tracking: Engine Idle", "Idle Tracking: Update Timer"
    SpoofIdleFocusTrue = true,      -- Force "Idle Tracking: Focus Changed" arg1 = true when unfocused

    -- Phase Progression (A1 - Part 1 + Part 2)
    RushButtonsFirst = true,        -- Hold Coins purely for Buttons + Completion before spending on Eggs/Merchant/Cocoa
    AutoBuyButtons = true,
    AutoCompleteTycoon = true,      -- Invokes BT_Settle on 100% completion for 20x Flannel Gift
    AutoCompletePart2 = true,       -- Invokes MH_Conclude on 100% Part 2 completion
    BuyOptionalPart2Buttons = false,-- Optional Zone8_Cannon (14.5T) & Zone8_RebirthShrine (15.3T) after required buttons
    TargetRebirths = 0,             -- 0 = Off (default); 3 = max 1.0x Huge/Titanic egg odds; 20 = max +400% Coins; -1 = infinite

    -- Farm & Combat Speed
    AutoFarm = true,
    AutoTap = true,
    AutoPetFocus = true,
    AutoSpreadZoneBreakables = true, -- Spread each pet onto its own highest-zone breakable; focus all pets on BonusChest/Pedestal
    AutoTeleportToTarget = true,
    AutoBuffPetSpeed = true,        -- Overrides LocalPlayer CalculateSpeedMultiplier() -> PetSpeedMultiplier
    PetSpeedMultiplier = 999,       -- Target speedMult (PetRendering multiplies petSpeed * petSpeedMult)
    FarmOrchardAndHay = true,
    AutoCollectOrbs = true,         -- Collects both Orbs and Lootbags from __THINGS.Orbs via "Orbs: Collect"
    TapInterval = 0.065,            -- Matches PS99 Swift Taps 8..16/s cap without 25 Hz overhead
    TapSendAutoClickerSignal = false, -- Skip AutoClicker_Nearby UI tween/coroutine FX spam; keep Breakables_PlayerDealDamage
    FarmLoopInterval = 0.10,        -- Pet & movement target refresh interval
    OrbSweepInterval = 0.50,        -- Sparse fallback sweep for delayed Lootbags alongside Orbs: Create event
    PedestalLowRungSweepIntervalSec = 20, -- In Zone 6-8, throttle 700-stud trips for R1-R2 pedestals to once every 20s

    -- Keep / Lock / Stock / Merchant (A2)
    KeepRung = 0,                   -- Ladder: 2=Rare..8=Secret manual; 0=Off in Part 1 (auto EarnRate Lock in Part 2 Zone 6+)
    AutoKeepPart2Pedestals = true,  -- In Part 2 Zone 6+, automatically lock top EarnRate pedestals for passive Ref[6..8] Coins/s
    Part2KeepMinRung = 4,           -- Minimum base rung equivalent (4=Legendary / 0.25x Ref) for Part 2 auto-lock
    Part2MinFarmPedestals = 1,      -- Keep 1 open pedestal for Token farming & Merchant placement in Part 2 (locks 5/6 -> 7/8)
    LockMinRung = 0,                -- 0 = follow KeepRung; or set >= 2 to override
    MinFarmPedestals = nil,         -- nil = adaptive; or set integer >= 1
    AutoLockUpgradeSwap = true,     -- Swap weakest locked pedestal by EarnRate (Cps * VariantMult) when a stronger pumpkin spawns
    AutoPlaceStock = true,          -- Enable auto-place ("next") + allocate held stock onto free pedestals
    AutoBuyMerchant = true,         -- Buy Merchant Mythical+/Exotic+/Legendary+ bands (gated by <= 5% Coins in Part 2 Rush)
    MerchantRequireButtonsComplete = false,
    MerchantRushRequireZone6 = true,-- Only buy Merchant during Rush once Zone 6+ (Ref=14.17M/s) is unlocked
    MerchantRushMaxCoinShare = 0.05,-- During Rush, buy Merchant band only if price <= 5% of current Coins
    MerchantActivateCoins = 100000000, -- Start buying Merchant bands at >= 100M Patch Coins (post-complete)
    MerchantMinSpareCoins = 50000000,  -- Keep at least 50M Patch Coins spare after a Merchant purchase (post-complete)
    KeepServerAutoMerchantOff = true, -- Prevent server HM_Sustain from buying low tiers into stock slots
    MerchantBandOrder = { "ExoticPlus", "MythicalPlus", "LegendaryPlus" },
    AllowedMerchantBands = {
        ExoticPlus = true,
        MythicalPlus = true,
        LegendaryPlus = true,
        EpicPlus = false,
        RarePlus = false,
    },

    -- Upgrades with PumpkinTokens (A3)
    AutoUpgrades = true,
    UpgradeTier1CheapFirst = true,  -- Buy all Tier 1 upgrades <= UpgradeCheapTier1MaxBaseCost before Priority Tier 2+
    UpgradeCheapTier1MaxBaseCost = 50,
    UpgradePriority = {
        "PumpkinCoins",
        "PumpkinDamage",
        "RespawnSpeed",
        "SpawnLuck",
        "ChaseOdds",
        "EggLuck",
        "StockSlots",
        "MerchantLuck",
    },
    UpgradeCheapCatchupRatio = 0.40, -- Buy lower-priority track if cost <= 40% of blocked top priority (0 = strict linear)

    -- Boosts, Fruits, Hot Cocoa Stand & Flannel Gifts (A2/A4)
    AutoConsumeBoosts = true,
    BoostRefreshSeconds = 15,
    AllowedConsumableBoosts = {
        ["Patch Coin Boost"] = true,
        ["Pumpkin Damage Boost"] = true,
        ["Island Luck Boost"] = true,
    },

    AutoConsumeFruits = true,
    FruitTargetStack = 20,          -- Keep up to 20x stacked fruits (e.g. Apple = +30% Pet Damage)
    FruitMinRefillMissing = 4,      -- Batch refill when >= 4 queue slots open (or immediately when 0 active)
    FruitConsumeCooldownSec = 6,
    AllowedFruits = {
        Apple = true,
    },

    AutoCocoaStand = true,
    CocoaRequireButtonsComplete = false, -- During Rush, gated by CocoaMinIncomePerSec (>= 3.5M/s); set true to block until Part 1 done
    CocoaMinIncomePerSec = 3500000,      -- Tier 1 Cocoa costs 100M/min (1.67M/s) for +50% Coins -> profitable above 3.33M/s
    CocoaRushDamageMinIncomePerSec = 15000000, -- Add Damage Cocoa (+50% dmg) during Rush once income >= 15M/s
    CocoaRushLuckMinIncomePerSec = 30000000,   -- Add IslandLuck Cocoa (+25% luck) during Rush once income >= 30M/s
    CocoaIncomeMinSampleSec = 45,        -- Require >= 45s sustained rate samples before turning on during Rush
    CocoaActivateCoins = 300000000,      -- Activate Hot Cocoa Stand at >= 300M Patch Coins
    CocoaMaintainMinutes = 2,
    CocoaBuyStepMinutes = 2,             -- Buy 1-2 minutes per refresh cycle while maintaining >= CocoaMinSpareCoins
    CocoaMinSpareCoins = 150000000,      -- Keep at least 150M Patch Coins spare after Cocoa purchase
    CocoaRushAxes = { "Coins" },         -- During Rush with KeepRung=0, only Coins Cocoa is net-positive near ~3.5M/s
    CocoaAxes = { "Coins", "Damage", "IslandLuck" },

    AutoOpenGifts = true,
    GiftBatchAmount = 8,            -- Server clamp [1, 8]

    -- Egg Hatching (Smart Early Bootstrap + Post-Buttons Zone 8 Golden Ridge)
    AutoHatch = true,
    AutoEarlyHatchForDamage = true,      -- Hatch unlocked eggs during rush when team EventDamage is below target
    EarlyHatchMaxPerEgg = 8,             -- Minimum basic hatch cap before Gold/Rainbow craft upgrade mode (scales up with maxEquip)
    EarlyHatchBasicMaxCap = 25,          -- Max basic-only hatches on Zone 1-2 before Gold/Rainbow machine unlocks
    EarlyHatchUpgradeWithCraft = true,   -- Hatch past basic cap during Rush when Gold/Rainbow machine is unlocked
    EarlyHatchMaxCoinsPerEgg = 35000000, -- Base upgrade hatch cap (auto-scales to full Rainbow team budget for Part 2 Eggs 6-8)
    EarlyHatchLowHatchMaxEggs = 300,     -- Early craft hatch egg cap on Part 1 Eggs for low-hatch (maxHatch < 4) accounts
    EarlyHatchPart2RainbowMinEggs = 1300,-- Minimum egg cap on Part 2 Eggs 6-8 so low/mid-hatch accounts reach full Rainbow team
    EarlyHatchTargetVariantMult = 4,     -- Target Rainbow tier (4x common EventDamage, or 2x when only Gold is unlocked)
    EarlyHatchTargetBestMult = 5.5,      -- Stop early once weakest >= Rainbow AND best non-Huge >= 5.5x
    EarlyHatchMaxShareOfNextButton = 0.25, -- Pause early upgrade hatch once Coins >= 75% of next critical button
    EarlyHatchMinBalanceRatio = 20,      -- Require Coins >= eggCost * 20 before spending on craft upgrade hatches
    EarlyHatchReserveCoins = true,       -- Temporarily reserve 1x egg cost during early bootstrap before buying buttons
    AutoEquipBestPets = true,            -- Ensure AutoEquipPets / EquipBest equips newly hatched stronger pets immediately
    TargetEggName = "Golden Ridge Egg",
    FallbackHighestUnlockedEgg = true,
    HatchDisableAnimation = true,
    HatchMinBatchMultiplier = 1,    -- Start hatching when Coins >= cost * maxBatch * mult (or >= cost * 1)
    HatchMoveMaxDist = 30,          -- Server allows CustomEggs_Hatch up to ~36 studs; <=30 overlaps Zone 5 breakables
    HatchCooldown = 0.02,

    -- Pet Crafting (Gold & Rainbow Machine)
    AutoMakeGold = true,                -- Automatically craft Normal pets -> Golden at plot GoldMachine
    AutoMakeRainbow = true,             -- Automatically craft Golden pets -> Rainbow at plot RainbowMachine
    CraftEventPetsOnly = true,          -- Restrict crafting to PumpkinTycoon event pets
    CraftProtectShiny = true,           -- Skip Shiny pets (sh == true)
    CraftProtectLocked = true,          -- Skip locked pets (_lk == true / IsLocked())
    CraftProtectEquipped = true,        -- Subtract currently equipped stack counts via PetCmds.GetEquipped()
    CraftReserveMinTeamSlots = true,    -- Preserve at least PetCmds.GetMaxEquipped() total pets across inventory
    CraftRequireButtonComplete = true,  -- Require plot GoldMachine / RainbowMachine button to be owned before crafting
    CraftMinBatch = 1,                  -- Minimum crafted output pets per stack before triggering a machine trip
    CraftPostCompleteMinBatch = 5,      -- Minimum crafted output pets per stack to trigger a craft trip while AFK post-complete hatching
    CraftMaxBatchPerInvoke = 25,        -- Max crafted pets per single Network.Invoke call (chunks larger stacks)
    CraftCheckIntervalSec = 1.0,        -- Seconds between craft eligibility scans
    CraftEarlyHatchYieldIntervalSec = 8.0, -- Yield early bootstrap hatching every 8s to batch 5-7x Gold -> Rainbow crafts with minimal travel overhead
    CraftHatchYieldIntervalSec = 30.0,  -- Post-complete AFK hatch yield interval (30s) to maximize Huge/Titanic hatch uptime
    CraftFailCooldownSec = 10,          -- Cooldown backoff after a failed machine invoke

    -- Wild Hunt, Sighting & Pet Net Store (Part 2)
    AutoHuntWild = true,                -- Scan all owned zones & catch wild pets via RU_Ensnare (3s cooldown)
    AutoCatchSighting = true,           -- Catch Boss Turkey Sightings (Huge/Titanic/Gargantuan) via PV_Glimpse
    HuntMinTier = 4,                    -- 0=Any, 1=Uncommon+, 2=Rare+, 3=Epic+, 4=Huges only
    HuntVariantsOnly = false,           -- Only catch Golden/Rainbow/Shiny wild pets
    HuntAlwaysCatchHuges = true,        -- Always allow Huge wild pets even when HuntVariantsOnly=true
    HuntUltraOnHuge = true,             -- Use Ultra Pet Net first on Huges/Sightings and save it exclusively for them
    HuntUseNormalNetOnHuge = true,      -- Fallback to Pet Net on Huges/Sightings when 0 Ultra Pet Nets remain
    HuntMinCatchChance = 0,             -- Optional minimum catch probability (0..1)
    DisableServerAutoHunt = true,       -- Turn off server 80-stud/6s Auto Hunt when AutoHuntWild is active
    AutoBuyNetStore = true,             -- Auto buy Pet Net Store via Merchant_RequestPurchase
    KeepServerAutoNetsOff = true,       -- Turn off server AutoBuyNets so Rush Coins budget is respected
    NetStoreBuyUltra = true,            -- Always buy Ultra Pet Net whenever affordable (even during Rush)
    NetStoreBuyNormal = true,           -- Buy Pet Net post-buttons or during Rush when price <= NetStoreMaxRushCoinShare * Coins
    NetStoreMaxRushCoinShare = 0.05,    -- During Rush, buy normal Pet Net only if price <= 5% of current Coins (0 = post-buttons only)
    NetStoreMinSpareCoins = 0,          -- Minimum Coins to keep after Net Store purchase (post-buttons)
    NetStoreCheckIntervalSec = 4.0,     -- Seconds between Net Store shelf checks

    -- Server-Wide Turkey Boss (Part 2 TurkeyArena)
    AutoTurkeyBoss = true,              -- Fly to TurkeyArena and fight Turkey Boss whenever TurkeyAlive == true
    TurkeyBossRequireCannon = false,    -- false = attempt direct fly even without Zone8_Cannon; true = require Cannon / Rebirth >= 1
    TurkeyBossMinShareStop = 0,         -- 0 = stay until boss dies/despawns; > 0 (e.g. 0.015) = leave once PumpkinTurkeyShare >= threshold
    TurkeyBossNoDamageTimeoutSec = 25,  -- Abort spawn if 0 share after 25s attacking without Cannon so farm is never stalled
    TurkeyBossStandOffset = 18,         -- Horizontal stand distance (studs) from boss center (inside 20-stud TapReach & 150-stud TurkeyReach)

    -- Optional Event Pass (disabled by default; enable when desired)
    AutoEventPass = false,

    -- Map & Render Optimization
    UltraLowRAM = false,                -- Optional ultra-low RAM preset (PotatoMode + ReduceOrbs + child-cleared Eggs/ShinyRelics/ZoneEggs + slower intervals)
    OptimizeMap = true,                 -- Master toggle for world cleanup + visual hiding + lighting/FX reduction
    StripWorldClutter = true,           -- Destroy unused world maps/props (PSX Portal, Border, Ornaments, __DEBRIS)
    HideIslandVisuals = true,           -- Make PumpkinTycoonIslands, __THINGS.Plots, Pads, Pumpkins invisible + strip decals/FX (when 3D is active)
    HideEntityVisuals = true,           -- Make Breakables, CustomEggs, Pets, Orbs & other players invisible (when 3D is active)
    OptimizeLightingAndEffects = true,  -- Disable Shadows/Sky/Bloom/Atmosphere/PostEffects/Particles and Terrain decoration
    SafeFloorEnabled = true,            -- Maintain invisible backup Baseplate under own plot to prevent void falls
    OptimizeScanInterval = 15.0,        -- Seconds between low-cost sweeps for newly streamed clutter/containers

    -- Dashboard UI
    ShowKaitunUI = true,                -- Full-screen black dashboard overlay + Set3dRenderingEnabled(false)

    -- Discord Pet Drop Webhook (Huge / Titanic / Gargantuan; runs alongside fixed global webhook)
    WebhookEnabled = true,              -- Enables optional personal WebhookUrl (does not disable built-in global webhook)
    WebhookUrl = "",                    -- Personal Discord Webhook URL (https://discord.com/api/webhooks/...)
    WebhookCategories = {
        Huge = true,
        Titanic = true,
        Gargantuan = true,
    },
    WebhookPollInterval = 1.0,          -- Snapshot poll interval (seconds)
    WebhookSendTestOnStart = false,     -- Send one test notification on startup
}

local function ApplyConfigDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            if type(v) == "table" then
                local clone = {}
                ApplyConfigDefaults(clone, v)
                dst[k] = clone
            else
                dst[k] = v
            end
        elseif type(v) == "table" and type(dst[k]) == "table" and #v == 0 then
            ApplyConfigDefaults(dst[k], v)
        end
    end
end

local Config = {}
do
    local userConfig = type(getgenv().Config) == "table" and getgenv().Config or {}
    local userSet = {
        ShowKaitunUI = userConfig.ShowKaitunUI ~= nil,
        WebhookPollInterval = userConfig.WebhookPollInterval ~= nil,
        CraftCheckIntervalSec = userConfig.CraftCheckIntervalSec ~= nil,
        OptimizeScanInterval = userConfig.OptimizeScanInterval ~= nil,
    }
    ApplyConfigDefaults(Config, userConfig)
    ApplyConfigDefaults(Config, DEFAULT_CONFIG)
    if Config.UltraLowRAM then
        if not userSet.ShowKaitunUI then
            Config.ShowKaitunUI = true
        end
        if not userSet.WebhookPollInterval then
            Config.WebhookPollInterval = math.max(tonumber(Config.WebhookPollInterval) or 1.0, 3.0)
        end
        if not userSet.CraftCheckIntervalSec then
            Config.CraftCheckIntervalSec = math.max(tonumber(Config.CraftCheckIntervalSec) or 1.0, 2.5)
        end
        if not userSet.OptimizeScanInterval then
            Config.OptimizeScanInterval = math.max(tonumber(Config.OptimizeScanInterval) or 15.0, 15.0)
        end
    end
end
if not Config.Enabled then
    return
end

-- ============================================================================
-- 2. SERVICES & RUNTIME STATE
-- ============================================================================
if not game:IsLoaded() then
    pcall(function()
        game.Loaded:Wait()
    end)
end
while Config.Enabled and not game:IsLoaded() do
    task.wait(0.1)
end
if not Config.Enabled then
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = nil
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
while Config.Enabled and not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end
if not Config.Enabled then
    return
end

local SessionToken = HttpService:GenerateGUID(false)
local Connections = {}

local Runtime = {
    Token = SessionToken,
    Running = true,
    Stats = {
        StartTime = os.time(),
        Phase = "Initializing",
        Coins = 0,
        CoinsPerSec = 0,
        Tokens = 0,
        ButtonsDone = 0,
        ButtonsTotal = 0,
        Part1Complete = false,
        Part2Complete = false,
        TycoonComplete = false,
        CompletedClaimed = false,
        Completed2Claimed = false,
        Rebirths = 0,
        IslandLuck = 0,
        ActiveTargetUid = nil,
        ActiveTargetDesc = "None",
        IsHatching = false,
        EggsHatched = 0,
        EarlyEggsHatched = 0,
        GoldCrafted = 0,
        RainbowCrafted = 0,
        ShinyCrafted = 0,
        LockedPedestals = 0,
        MaxKeepSlots = 0,
        TeamPowerWeakest = 0,
        TeamPowerBest = 0,
        GiftsOpened = 0,
        NetsBought = 0,
        WildThrows = 0,
        WildCaught = 0,
        WildHugesCaught = 0,
        SightingsCaught = 0,
        FightingTurkeyBoss = false,
        TurkeyBossShare = 0,
        TurkeyBossHealth = 0,
        TurkeyBossMaxHealth = 0,
        TurkeyBossFights = 0,
        TurkeyBossKills = 0,
        PetSpeedMult = 1,
        AfkPulsesRoblox = 0,
        AfkPulsesP99 = 0,
        BlockedMoveServer = 0,
        BlockedIdleTelemetry = 0,
        MapDestroyedCount = 0,
        VisualsHiddenCount = 0,
        WebhookSent = 0,
    },
    Cache = {
        IslandBox = nil,
        IslandBoxAt = 0,
        Buttons = nil,
        ButtonsAt = 0,
        CriticalButtons = nil,
        CriticalButtonsPart2 = nil,
        LastComplete2FailAt = 0,
        LastRebirthFailAt = 0,
        EggCostCache = {},
        EggBasePowerCache = {},
        EggCommonEventDmgCache = {},
        EarlyHatchedByEgg = {},
        EarlyCoinsSpentByEgg = {},
        ReserveEarlyEggCost = 0,
        TrackedCoinsSpent = 0,
        CoinRateSamples = {},
        LastCoinRateSampleAt = 0,
        LastGrossCoins = nil,
        CumulativeCoinsEarned = 0,
        LastEquipBestAt = 0,
        TeamPowerSnapshot = nil,
        TeamPowerSnapshotAt = 0,
        BoostConsumeCooldown = {},
        FruitConsumeCooldown = {},
        LastEarlyHatchLogAt = 0,
        LastKeepInvoked = nil,
        LastServerAutoMerchant = nil,
        LastAutoPlace = nil,
        PetSpeedHookActive = false,
        PetSpeedHookWrapper = nil,
        PetSpeedCreatedConnBound = false,
        PetSpeedLastTargetMult = nil,
        LastPetSpeedRefreshAt = 0,
        AntiAfkHookActive = false,
        AntiAfkEnv = nil,
        IdleTrackingDisabled = false,
        IdleTrackingScript = nil,
        IdleTrackingWatchBound = false,
        NetFireHookTarget = nil,
        NetFireOrig = nil,
        LastRobloxAfkPulseAt = 0,
        LastP99AfkPulseAt = 0,
        LastP99SafeResetAt = 0,
        LastMoveServerBlockLogAt = 0,
        SavedLightingState = nil,
        SafeFloorPart = nil,
        MapOptimizerInitialized = false,
        MapClutterClearedInEvent = false,
        Is3dRenderingEnabled = (Config.ShowKaitunUI == false),
        PlayerCharConns = setmetatable({}, { __mode = "k" }),
        VisualStripQueue = {
            head = 1,
            tail = 0,
            items = {},
            cols = {},
            queued = setmetatable({}, { __mode = "k" }),
            maxSize = 2500,
        },
        VisualStripHbBound = false,
        LastDebrisSweepAt = 0,
        LastConnPruneAt = 0,
        MyIslandResweepToken = 0,
        UltraLowRamApplied = false,
        PrevPotatoMode = nil,
        LastOptimizeScanAt = 0,
        LastButtonsDoneForDecor = -1,
        PlotSavePlot = nil,
        PlotSaveEntries = {},
        PlotSaveConnsBound = {},
        PedInfoVer = -1,
        PedInfoCache = nil,
        TapReachVal = nil,
        TapReachAt = 0,
        TargetEggCache = {},
        TargetEggSig = nil,
        TargetsBufA = {},
        TargetsBufB = {},
        TargetsUseB = false,
        EntryPoolA = {},
        EntryPoolB = {},
        EmergencyScratch = {},
        AllByClassScratch = {},
        LockedPedScratch = {},
        ZonePoolScratch = {},
        PoolByModelScratch = {},
        ClaimedCountScratch = {},
        NeedAssignScratch = {},
        ActiveTargetCopy = {},
        OrbSweepIds = {},
        OrbSweepSeen = {},
        CachedOrbRemote = nil,
        OrbsCreateConnBound = false,
        ItemsUpdateConnBound = false,
        TutorialDonePlot = nil,
        AllUpgradesMaxed = false,
        AllUpgradesMaxedAt = 0,
        GiftEmptyBoxesRef = nil,
        GiftBagDirty = true,
        WebhookInvDirty = true,
        WebhookLastSnapshot = nil,
        WebhookLastContainer = nil,
        WebhookLastInvRef = nil,
        WebhookLastReadAt = 0,
        LastJoinAttemptAt = 0,
        LastTutorialInvokeAt = 0,
        LastPolicyInvokeAt = 0,
        LastCocoaCheckAt = 0,
        LastGiftAttemptAt = 0,
        LastPassCheckAt = 0,
        LastButtonsStepAt = 0,
        LastKeepLockStepAt = 0,
        LastUpgradesStepAt = 0,
        LastBoostsStepAt = 0,
        LastFruitsStepAt = 0,
        LastGiftsStepAt = 0,
        LastNetStoreStepAt = 0,
        LastNetStoreFailAt = 0,
        LastNetStoreShelfFetchAt = 0,
        LastNetStoreAutoSyncAt = 0,
        LastWildStepAt = 0,
        LastWildThrowAt = 0,
        LastWildFailAt = 0,
        LastHuntAutoSyncAt = 0,
        SightingHookBound = false,
        ActiveSighting = nil,
        WildSpeciesMap = nil,
        WildSlotCooldown = {},
        NetStoreShelfCache = nil,
        TurkeyBossActiveEndsAt = 0,
        TurkeyBossEngagedAt = 0,
        TurkeyBossSkippedEndsAt = 0,
        TurkeyBossReturnPos = nil,
        TurkeyBossLastHealth = nil,
        MoveLockUntil = 0,
        MachineSessionDepth = 0,
        HatchYieldUntil = 0,
        HatchInFlight = false,
        LastTeleportAt = 0,
        LastCocoaFailAt = 0,
        LastMerchantFailAt = 0,
        LastCraftCheckAt = 0,
        LastCraftTripAt = 0,
        PendingCraftReadySince = 0,
        CraftFailUntil = { Gold = 0, Rainbow = 0 },
        CraftEventPetSet = nil,
        KaitunGui = nil,
        KaitunUiToken = nil,
        WebhookThumbnails = {},
        WebhookWarnedState = nil,
        WebhookStartupTestDone = false,
    },
    Helpers = {},
}

local KAITUN_GUI_NAME = "Kaitun_Dashboard_UI"

local function Set3dRenderingSafe(enabled)
    local active = (enabled == true)
    if Runtime.Cache then
        Runtime.Cache.Is3dRenderingEnabled = active
    end
    pcall(function()
        (RunService :: any):Set3dRenderingEnabled(active)
    end)
    if Runtime.Helpers and Runtime.Helpers.On3dRenderingChanged then
        Runtime.Helpers.On3dRenderingChanged(active)
    end
end

local function DestroyExistingKaitunGui(targetParent)
    if not targetParent then
        return
    end
    local existing = targetParent:FindFirstChild(KAITUN_GUI_NAME)
    if existing then
        pcall(existing.Destroy, existing)
    end
end

local function CleanupKaitunDashboard()
    local activeGui = Runtime.Cache and Runtime.Cache.KaitunGui
    if activeGui then
        Runtime.Cache.KaitunGui = nil
        if activeGui.Parent then
            pcall(activeGui.Destroy, activeGui)
        end
    end
    if Runtime.Cache then
        Runtime.Cache.KaitunUiToken = nil
    end
    if LocalPlayer then
        DestroyExistingKaitunGui(LocalPlayer:FindFirstChild("PlayerGui"))
    end
    local okCg, cg = pcall(function()
        return (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
    end)
    if okCg and cg then
        DestroyExistingKaitunGui(cg)
    end
    Set3dRenderingSafe(true)
end

local function IsRunning()
    return Runtime.Running and Config.Enabled and Runtime.Token == SessionToken
end

-- Register an early teardown guard so re-executing during cold boot cancels this waiter.
Runtime.Teardown = function()
    Runtime.Running = false
    for _, conn in ipairs(Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(Connections)
    CleanupKaitunDashboard()
end
getgenv()[GEN_KEY] = Runtime

local function Log(level, fmt, ...)
    if level == "DEBUG" and not Config.Debug then
        return
    end
    local ok, text = pcall(string.format, fmt, ...)
    print(string.format("[PumpkinKaitun][%s] %s", level, ok and text or tostring(fmt)))
end

local function BindConn(signal, fn)
    if not signal then
        return nil
    end
    local conn = signal:Connect(fn)
    table.insert(Connections, conn)
    return conn
end

function Runtime.Helpers.PruneConnections()
    local n = #Connections
    if n == 0 then
        return 0
    end
    local write = 1
    local removed = 0
    for i = 1, n do
        local conn = Connections[i]
        local keep = false
        if conn ~= nil then
            if typeof(conn) == "RBXScriptConnection" then
                keep = conn.Connected
            else
                keep = true
            end
        end
        if keep then
            if write ~= i then
                Connections[write] = conn
            end
            write = write + 1
        else
            removed = removed + 1
        end
    end
    for i = write, n do
        Connections[i] = nil
    end
    return removed
end

-- ============================================================================
-- 3. MODULE RESOLUTION (AUTOEXEC BOOT WAIT)
-- ============================================================================
local function GetBootReadiness()
    local lib = ReplicatedStorage:FindFirstChild("Library")
    if not lib then
        return false, "Library"
    end
    if lib:GetAttribute("IsLoaded") ~= true then
        return false, "Library.IsLoaded"
    end
    if not ReplicatedStorage:FindFirstChild("Assets") then
        return false, "Assets"
    end
    local things = Workspace:FindFirstChild("__THINGS")
    if not things or not things:FindFirstChild("Instances") or not things:FindFirstChild("__INSTANCE_CONTAINER") then
        return false, "Workspace.__THINGS"
    end
    if LocalPlayer:GetAttribute("__LOADED") ~= true then
        return false, "LocalPlayer.__LOADED"
    end
    if not LocalPlayer:FindFirstChild("PlayerGui") then
        return false, "PlayerGui"
    end
    local clientFolder = lib:FindFirstChild("Client")
    local saveInst = clientFolder and clientFolder:FindFirstChild("Save")
    if not saveInst then
        return false, "SaveModule"
    end
    local okReq, saveMod = pcall(require, saveInst)
    if not okReq or type(saveMod) ~= "table" or type(saveMod.Get) ~= "function" then
        return false, "SaveApi"
    end
    local okData, saveData = pcall(saveMod.Get)
    if not okData or type(saveData) ~= "table" then
        return false, "SaveData"
    end
    return true, "Ready"
end

local function WaitBootReady()
    local startAt = os.clock()
    local lastLogAt = 0
    local didWait = false

    while IsRunning() do
        local ready, stage = GetBootReadiness()
        if ready then
            if didWait then
                Log("INFO", "PS99 boot ready in %.1fs; resolving modules.", os.clock() - startAt)
            end
            return true
        end

        didWait = true
        local elapsed = os.clock() - startAt
        if (lastLogAt == 0 and elapsed >= 1.5) or (lastLogAt > 0 and elapsed - lastLogAt >= 15) then
            lastLogAt = elapsed
            Log("INFO", "Waiting for PS99 boot (stage=%s, elapsed=%.1fs)...", tostring(stage), elapsed)
        end
        task.wait(0.25)
    end

    return false
end

if not WaitBootReady() then
    return
end

local Library = ReplicatedStorage:FindFirstChild("Library") or ReplicatedStorage:WaitForChild("Library", 30)

local function SafeRequire(parent, ...)
    local cur = parent
    for _, childName in ipairs({ ... }) do
        if not cur then
            return nil
        end
        cur = cur:FindFirstChild(childName) or cur:WaitForChild(childName, 10)
    end
    if not cur then
        return nil
    end
    local ok, mod = pcall(require, cur)
    return ok and mod or nil
end

local Modules = {
    -- Core Client & Util
    Network = SafeRequire(Library, "Client", "Network"),
    Signal = SafeRequire(Library, "Signal"),
    Save = SafeRequire(Library, "Client", "Save"),
    FFlags = SafeRequire(Library, "Client", "FFlags") or SafeRequire(Library, "Universal", "FFlags"),
    Variables = SafeRequire(Library, "Variables") or SafeRequire(Library, "Client", "Variables"),
    SettingsCmds = SafeRequire(Library, "Client", "SettingsCmds"),
    CurrencyCmds = SafeRequire(Library, "Client", "CurrencyCmds"),
    BoostCmds = SafeRequire(Library, "Client", "BoostCmds"),
    FruitCmds = SafeRequire(Library, "Client", "FruitCmds"),
    InstancingCmds = SafeRequire(Library, "Client", "InstancingCmds"),
    ClientPlot = SafeRequire(Library, "Client", "PlotCmds", "ClientPlot"),
    BreakableFrontend = SafeRequire(Library, "Client", "BreakableFrontend"),
    AutoFarmCmds = SafeRequire(Library, "Client", "AutoFarmCmds"),
    PlayerPet = SafeRequire(Library, "Client", "PlayerPet"),
    PetCmds = SafeRequire(Library, "Client", "PetCmds"),
    MasteryCmds = SafeRequire(Library, "Client", "MasteryCmds"),
    MachineCmds = SafeRequire(Library, "Client", "MachineCmds"),
    DaycareCmds = SafeRequire(Library, "Client", "DaycareCmds"),
    ExclusiveDaycareCmds = SafeRequire(Library, "Client", "ExclusiveDaycareCmds"),
    TabController = SafeRequire(Library, "Client", "TabController"),
    CustomEggsCmds = SafeRequire(Library, "Client", "CustomEggsCmds"),
    EggCmds = SafeRequire(Library, "Client", "EggCmds"),
    EventUpgradeCmds = SafeRequire(Library, "Client", "EventUpgradeCmds"),
    LootboxLocation = SafeRequire(Library, "Client", "LootboxCmds", "LocationFinder"),
    InventoryCmds = SafeRequire(Library, "Client", "InventoryCmds"),
    GlobalExistCmds = SafeRequire(Library, "Client", "GlobalExistCmds"),
    RAPCmds = SafeRequire(Library, "Client", "RAPCmds"),
    Directory = SafeRequire(Library, "Directory"),
    Items = SafeRequire(Library, "Items"),
    PetItem = SafeRequire(Library, "Items", "PetItem"),
    LootboxItem = SafeRequire(Library, "Items", "LootboxItem"),
    MiscItem = SafeRequire(Library, "Items", "MiscItem"),

    -- PumpkinTycoon Types & Utils
    PumpkinTycoon = SafeRequire(Library, "Types", "PumpkinTycoon"),
    ButtonsTypes = SafeRequire(Library, "Types", "PumpkinTycoon", "Buttons"),
    ChaseTypes = SafeRequire(Library, "Types", "PumpkinTycoon", "Chase"),
    LadderTypes = SafeRequire(Library, "Types", "PumpkinTycoon", "Ladder"),
    MerchantTypes = SafeRequire(Library, "Types", "PumpkinTycoon", "Merchant"),
    UpgradesTypes = SafeRequire(Library, "Types", "PumpkinTycoon", "Upgrades"),
    WildTypes = SafeRequire(Library, "Types", "PumpkinTycoon", "Wild"),
    LootboxTypes = SafeRequire(Library, "Types", "Lootboxes"),

    PumpkinButtonsUtil = SafeRequire(Library, "Util", "PumpkinTycoonButtons"),
    PumpkinUpgradesUtil = SafeRequire(Library, "Util", "PumpkinTycoonUpgrades"),
    PumpkinBoostsUtil = SafeRequire(Library, "Util", "PumpkinTycoonBoosts"),
    PumpkinCocoaUtil = SafeRequire(Library, "Util", "PumpkinTycoonCocoa"),
    PumpkinDamageUtil = SafeRequire(Library, "Util", "PumpkinTycoonDamage"),
    PumpkinEarnUtil = SafeRequire(Library, "Util", "PumpkinTycoonEarn"),
    PumpkinGiftUtil = SafeRequire(Library, "Util", "PumpkinTycoonGift"),
    PumpkinWildUtil = SafeRequire(Library, "Util", "PumpkinTycoonWild"),
    PumpkinHuntUtil = SafeRequire(Library, "Util", "PumpkinTycoonHunt"),
    PumpkinStoreUtil = SafeRequire(Library, "Util", "PumpkinTycoonStore"),
    PumpkinSightingUtil = SafeRequire(Library, "Util", "PumpkinTycoonSighting"),
    PumpkinTurkeyUtil = SafeRequire(Library, "Util", "PumpkinTycoonTurkey"),
    PumpkinIslandCmds = SafeRequire(Library, "Client", "PumpkinTycoonCmds", "Island"),
    PumpkinTurkeyCmds = SafeRequire(Library, "Client", "PumpkinTycoonCmds", "Turkey"),

    -- Optional Event Pass
    EventPassTypes = SafeRequire(Library, "Types", "EventPass"),
    EventPassUtil = SafeRequire(Library, "Util", "EventPassUtil"),
}

-- EventCmds submodules (loaded via PumpkinTycoonCmds if available)
local PT_Cmds = SafeRequire(Library, "Client", "PumpkinTycoonCmds")
local PT_Buttons = PT_Cmds and SafeRequire(Library, "Client", "PumpkinTycoonCmds", "Buttons")
local PT_AutoBreak = PT_Cmds and SafeRequire(Library, "Client", "PumpkinTycoonCmds", "AutoBreak")

local CRITICAL_MODULE_PATHS = {
    Network = { "Client", "Network" },
    Save = { "Client", "Save" },
    InstancingCmds = { "Client", "InstancingCmds" },
    ClientPlot = { "Client", "PlotCmds", "ClientPlot" },
    PumpkinTycoon = { "Types", "PumpkinTycoon" },
    PumpkinButtonsUtil = { "Util", "PumpkinTycoonButtons" },
}

local function CollectMissingCriticalModules()
    local missing = {}
    for key, path in pairs(CRITICAL_MODULE_PATHS) do
        if not Modules[key] then
            Modules[key] = SafeRequire(Library, table.unpack(path))
        end
        if not Modules[key] then
            table.insert(missing, key)
        end
    end
    return missing
end

local function EnsureCriticalModules()
    local missing = CollectMissingCriticalModules()
    if #missing == 0 then
        return true
    end

    for _ = 1, 5 do
        if not IsRunning() then
            return false
        end
        task.wait(0.5)
        missing = CollectMissingCriticalModules()
        if not PT_Cmds then
            PT_Cmds = SafeRequire(Library, "Client", "PumpkinTycoonCmds")
        end
        if PT_Cmds and not PT_Buttons then
            PT_Buttons = SafeRequire(Library, "Client", "PumpkinTycoonCmds", "Buttons")
        end
        if PT_Cmds and not PT_AutoBreak then
            PT_AutoBreak = SafeRequire(Library, "Client", "PumpkinTycoonCmds", "AutoBreak")
        end
        if #missing == 0 then
            return true
        end
    end

    table.sort(missing)
    Log("WARN", "Some modules failed to resolve after boot: %s", table.concat(missing, ", "))
    return false
end

EnsureCriticalModules()
if not IsRunning() then
    return
end

local NET_FIRE_HOOK_KEY = "_PumpkinTycoonKaitun_NetFireHookTarget"

function Runtime.Helpers.DetectMobileAntiAfk()
    if Runtime.Cache.AntiAfkEnv then
        return Runtime.Cache.AntiAfkEnv
    end
    local isTouchOnly = false
    pcall(function()
        if UserInputService then
            isTouchOnly = (UserInputService.TouchEnabled == true) and (UserInputService.KeyboardEnabled ~= true)
        end
    end)
    local execName = ""
    pcall(function()
        if type(identifyexecutor) == "function" then
            execName = tostring(identifyexecutor() or "")
        elseif type(getexecutorname) == "function" then
            execName = tostring(getexecutorname() or "")
        end
    end)
    local lowerExec = string.lower(execName)
    local isMobileExec = false
    for _, marker in ipairs({ "delta", "arceus", "codex", "fluxus", "hydrogen", "vegax", "cryptic" }) do
        if string.find(lowerExec, marker, 1, true) then
            isMobileExec = true
            break
        end
    end
    local envInfo = {
        isTouchOnly = isTouchOnly,
        isMobileExec = isMobileExec,
        execName = execName,
        isMobile = isTouchOnly or isMobileExec,
    }
    Runtime.Cache.AntiAfkEnv = envInfo
    return envInfo
end

function Runtime.Helpers.GetEffectiveAntiAfkStrategy()
    local envInfo = Runtime.Helpers.DetectMobileAntiAfk()
    local mode = string.lower(tostring(Config.AntiAfkMode or "auto"))
    if mode ~= "safe" and mode ~= "hook" then
        mode = "auto"
    end
    if not Config.AntiAFK or not Config.AntiAFKP99 then
        return mode, envInfo, false
    end
    local idleDisabled = (Runtime.Cache.IdleTrackingDisabled == true)
    local useHookFallback = (mode == "hook") or (mode == "auto" and not envInfo.isMobile and not idleDisabled)
    return mode, envInfo, useHookFallback
end

local function PulseRobloxAntiAfk()
    if not VirtualUser then
        return false
    end
    local ok = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
    if ok then
        Runtime.Cache.LastRobloxAfkPulseAt = os.clock()
        Runtime.Stats.AfkPulsesRoblox = (Runtime.Stats.AfkPulsesRoblox or 0) + 1
    end
    return ok
end

local function PulseP99AntiAfk()
    local _, _, useHookFallback = Runtime.Helpers.GetEffectiveAntiAfkStrategy()
    if not useHookFallback then
        return false
    end
    if not VirtualInputManager then
        local okVim, svc = pcall(game.GetService, game, "VirtualInputManager")
        if okVim and svc then
            VirtualInputManager = svc
        end
    end
    if not VirtualInputManager or not VirtualInputManager.SendKeyEvent then
        return false
    end
    if UserInputService and UserInputService.GetFocusedTextBox then
        local okTb, focusedBox = pcall(UserInputService.GetFocusedTextBox, UserInputService)
        if okTb and focusedBox ~= nil then
            return false
        end
    end
    local ok = pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
    end)
    if ok then
        Runtime.Cache.LastP99AfkPulseAt = os.clock()
        Runtime.Stats.AfkPulsesP99 = (Runtime.Stats.AfkPulsesP99 or 0) + 1
    end
    return ok
end

function Runtime.Helpers.PulseP99SafeIdleReset(isMobile)
    local net = Modules.Network
    if not net or type(net.Fire) ~= "function" then
        return false
    end
    local inputVal = isMobile and 7 or 0
    if Config.SpoofIdleFocusTrue then
        pcall(net.Fire, "Idle Tracking: Focus Changed", true)
    end
    local okStop = pcall(net.Fire, "Idle Tracking: Stop Timer", inputVal)
    if okStop then
        Runtime.Cache.LastP99SafeResetAt = os.clock()
        Runtime.Stats.AfkPulsesP99 = (Runtime.Stats.AfkPulsesP99 or 0) + 1
    end
    return okStop
end

local function RestoreAntiAfkNetworkHook()
    local rec = getgenv()[NET_FIRE_HOOK_KEY]
    if type(rec) == "table" then
        rec.enabled = false
        rec.runtime = nil
        rec.token = nil
        rec.config = nil
        rec.log = nil
        local hookedTarget = rec.target or Runtime.Cache.NetFireHookTarget
        local unhooked = false
        if hookedTarget and type(restorefunction) == "function" then
            local shouldRestore = true
            if type(isfunctionhooked) == "function" then
                local okH, hooked = pcall(isfunctionhooked, hookedTarget)
                shouldRestore = okH and (hooked == true)
            end
            if shouldRestore then
                local okR = pcall(restorefunction, hookedTarget)
                if okR then
                    if type(isfunctionhooked) == "function" then
                        local okH2, stillHooked = pcall(isfunctionhooked, hookedTarget)
                        unhooked = (not okH2) or (stillHooked ~= true)
                    else
                        unhooked = true
                    end
                end
            else
                unhooked = true
            end
        end
        if unhooked then
            getgenv()[NET_FIRE_HOOK_KEY] = nil
        end
    elseif rec then
        if type(restorefunction) == "function" then
            pcall(restorefunction, rec)
        end
        getgenv()[NET_FIRE_HOOK_KEY] = nil
    elseif Runtime.Cache.NetFireHookTarget and type(restorefunction) == "function" then
        pcall(restorefunction, Runtime.Cache.NetFireHookTarget)
    end
    Runtime.Cache.AntiAfkHookActive = false
    Runtime.Cache.NetFireHookTarget = nil
    Runtime.Cache.NetFireOrig = nil
end

function Runtime.Helpers.DisableIdleScriptInstance(idleScript)
    if not idleScript or not (idleScript:IsA("LocalScript") or idleScript:IsA("Script")) then
        return false
    end
    pcall(function()
        idleScript.Disabled = true
    end)
    pcall(function()
        idleScript.Enabled = false
    end)
    local isDisabled = false
    local okCheck, resCheck = pcall(function()
        return idleScript.Disabled == true or idleScript.Enabled == false
    end)
    if okCheck then
        isDisabled = (resCheck == true)
    end
    if isDisabled then
        if Runtime.Cache.IdleTrackingScript ~= idleScript then
            Runtime.Cache.IdleTrackingScript = idleScript
            BindConn(idleScript:GetPropertyChangedSignal("Enabled"), function()
                if IsRunning() and Config.AntiAFK and Config.AntiAFKP99 and idleScript.Enabled then
                    pcall(function()
                        idleScript.Disabled = true
                        idleScript.Enabled = false
                    end)
                end
            end)
        end
        Runtime.Cache.IdleTrackingDisabled = true
        local mode = Runtime.Helpers.GetEffectiveAntiAfkStrategy()
        if mode == "auto" and Runtime.Cache.AntiAfkHookActive then
            RestoreAntiAfkNetworkHook()
        end
    end
    return isDisabled
end

function Runtime.Helpers.TryDisableIdleTracking()
    local ps = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts")
    local scriptsFolder = ps and ps:FindFirstChild("Scripts")
    local coreFolder = scriptsFolder and scriptsFolder:FindFirstChild("Core")
    local idleScript = coreFolder and coreFolder:FindFirstChild("Idle Tracking")
    if idleScript and Runtime.Helpers.DisableIdleScriptInstance(idleScript) then
        return true
    end

    if not Runtime.Cache.IdleTrackingWatchBound and LocalPlayer then
        Runtime.Cache.IdleTrackingWatchBound = true
        local function attachCoreWatcher(core)
            if not core then
                return
            end
            BindConn(core.ChildAdded, function(child)
                if IsRunning() and Config.AntiAFK and Config.AntiAFKP99 and child and child.Name == "Idle Tracking" then
                    if Runtime.Helpers.DisableIdleScriptInstance(child) then
                        Log("INFO", "Disabled late-loaded Idle Tracking script.")
                    end
                end
            end)
        end
        local function attachScriptsWatcher(scripts)
            if not scripts then
                return
            end
            local c = scripts:FindFirstChild("Core")
            if c then
                attachCoreWatcher(c)
                local idle = c:FindFirstChild("Idle Tracking")
                if idle then
                    Runtime.Helpers.DisableIdleScriptInstance(idle)
                end
            else
                BindConn(scripts.ChildAdded, function(child)
                    if IsRunning() and child and child.Name == "Core" then
                        attachCoreWatcher(child)
                        local idle = child:FindFirstChild("Idle Tracking")
                        if idle then
                            Runtime.Helpers.DisableIdleScriptInstance(idle)
                        end
                    end
                end)
            end
        end
        local function attachPlayerScriptsWatcher(playerScripts)
            if not playerScripts then
                return
            end
            local s = playerScripts:FindFirstChild("Scripts")
            if s then
                attachScriptsWatcher(s)
            else
                BindConn(playerScripts.ChildAdded, function(child)
                    if IsRunning() and child and child.Name == "Scripts" then
                        attachScriptsWatcher(child)
                    end
                end)
            end
        end
        if ps then
            attachPlayerScriptsWatcher(ps)
        else
            BindConn(LocalPlayer.ChildAdded, function(child)
                if IsRunning() and child and child.Name == "PlayerScripts" then
                    attachPlayerScriptsWatcher(child)
                end
            end)
        end
    end
    return Runtime.Cache.IdleTrackingDisabled == true
end

local function EnsureAntiAfkNetworkHook()
    local _, envInfo, useHookFallback = Runtime.Helpers.GetEffectiveAntiAfkStrategy()
    if not useHookFallback then
        if Runtime.Cache.AntiAfkHookActive then
            RestoreAntiAfkNetworkHook()
        end
        return
    end
    if not envInfo.isMobile and type(getconnections) == "function" then
        pcall(function()
            for _, conn in ipairs(getconnections(RunService.RenderStepped)) do
                local fn = conn and conn.Function
                if fn and debug and debug.getinfo then
                    local okInfo, info = pcall(debug.getinfo, fn)
                    local src = (okInfo and info and info.source) or ""
                    if string.find(src, "Idle Tracking", 1, true) then
                        if conn.Disable then
                            conn:Disable()
                        elseif conn.Disconnect then
                            conn:Disconnect()
                        end
                    end
                end
            end
        end)
    end
    local net = Modules.Network
    if not net or type(net.Fire) ~= "function" or type(hookfunction) ~= "function" then
        return
    end
    if Runtime.Cache.AntiAfkHookActive and Runtime.Cache.NetFireHookTarget == net.Fire then
        return
    end

    local existingRec = getgenv()[NET_FIRE_HOOK_KEY]
    if type(existingRec) == "table" and existingRec.installed == true and type(existingRec.orig) == "function" and existingRec.target == net.Fire then
        existingRec.runtime = Runtime
        existingRec.token = SessionToken
        existingRec.config = Config
        existingRec.log = Log
        existingRec.enabled = true
        Runtime.Cache.NetFireHookTarget = net.Fire
        Runtime.Cache.NetFireOrig = existingRec.orig
        Runtime.Cache.AntiAfkHookActive = true
        Log("INFO", "PS99 Anti-AFK fallback hook re-armed.")
        return
    end

    if type(isfunctionhooked) == "function" and type(restorefunction) == "function" then
        local okH, hooked = pcall(isfunctionhooked, net.Fire)
        if okH and hooked then
            pcall(restorefunction, net.Fire)
        end
    end

    local hookRec = {
        installed = false,
        enabled = true,
        runtime = Runtime,
        token = SessionToken,
        config = Config,
        log = Log,
        target = net.Fire,
        orig = nil,
    }
    local wrapper = function(eventName, ...)
        local origFire = hookRec.orig
        local rt = hookRec.runtime
        local cfg = hookRec.config
        local logFn = hookRec.log
        if hookRec.enabled and rt and rt.Running and rt.Token == hookRec.token and cfg and cfg.AntiAFK and cfg.AntiAFKP99 then
            if cfg.BlockNativeMoveServer and eventName == "Move Server" then
                rt.Stats.BlockedMoveServer = (rt.Stats.BlockedMoveServer or 0) + 1
                local now = os.clock()
                if now - (rt.Cache.LastMoveServerBlockLogAt or 0) >= 15 then
                    rt.Cache.LastMoveServerBlockLogAt = now
                    if logFn then
                        logFn("INFO", "Blocked PS99 AFK Move Server (#%d).", rt.Stats.BlockedMoveServer)
                    end
                end
                return
            elseif cfg.BlockNativeMoveServer and (eventName == "Idle Tracking: Engine Idle" or eventName == "Idle Tracking: Update Timer") then
                rt.Stats.BlockedIdleTelemetry = (rt.Stats.BlockedIdleTelemetry or 0) + 1
                return
            elseif cfg.SpoofIdleFocusTrue and eventName == "Idle Tracking: Focus Changed" then
                return origFire(eventName, true)
            end
        end
        return origFire(eventName, ...)
    end

    local hookedClosure = type(newcclosure) == "function" and newcclosure(wrapper) or wrapper
    local ok, prev = pcall(hookfunction, net.Fire, hookedClosure)
    if ok and type(prev) == "function" then
        hookRec.orig = prev
        hookRec.installed = true
        Runtime.Cache.NetFireHookTarget = net.Fire
        Runtime.Cache.NetFireOrig = prev
        Runtime.Cache.AntiAfkHookActive = true
        getgenv()[NET_FIRE_HOOK_KEY] = hookRec
        Log("INFO", "PS99 Idle Tracking & Move Server PC fallback hook enabled.")
    else
        Log("DEBUG", "Failed to hook Network.Fire for PS99 Anti-AFK: %s", tostring(prev))
    end
end

local function SetupAntiAfk()
    if not Config.AntiAFK then
        RestoreAntiAfkNetworkHook()
        return
    end

    local mode, envInfo = Runtime.Helpers.GetEffectiveAntiAfkStrategy()
    local idleDisabled = Runtime.Helpers.TryDisableIdleTracking()
    local _, _, useHookFallback = Runtime.Helpers.GetEffectiveAntiAfkStrategy()

    if useHookFallback then
        EnsureAntiAfkNetworkHook()
    else
        RestoreAntiAfkNetworkHook()
    end

    Log("INFO", "Anti-AFK ready (mode=%s, mobile=%s, idleDisabled=%s, hookFallback=%s).",
        tostring(mode),
        tostring(envInfo.isMobile),
        tostring(idleDisabled),
        tostring(useHookFallback))

    BindConn(LocalPlayer.Idled, function()
        if not IsRunning() or not Config.AntiAFK then
            return
        end
        if Config.AntiAFKRoblox then
            PulseRobloxAntiAfk()
        end
        if Config.AntiAFKP99 then
            Runtime.Helpers.PulseP99SafeIdleReset(envInfo.isMobile)
        end
    end)

    task.spawn(function()
        if Config.AntiAFKRoblox then
            PulseRobloxAntiAfk()
        end
        if Config.AntiAFKP99 then
            Runtime.Helpers.PulseP99SafeIdleReset(envInfo.isMobile)
            if useHookFallback then
                PulseP99AntiAfk()
            end
        end

        while IsRunning() do
            local _, curEnv, curHookFallback = Runtime.Helpers.GetEffectiveAntiAfkStrategy()
            task.wait(curHookFallback and 1 or 5)
            if not IsRunning() then
                break
            end
            if not Runtime.Cache.IdleTrackingDisabled then
                Runtime.Helpers.TryDisableIdleTracking()
            end
            _, curEnv, curHookFallback = Runtime.Helpers.GetEffectiveAntiAfkStrategy()
            if curHookFallback then
                EnsureAntiAfkNetworkHook()
            elseif Runtime.Cache.AntiAfkHookActive then
                RestoreAntiAfkNetworkHook()
            end

            local now = os.clock()
            if Config.AntiAFK and Config.AntiAFKP99 and curHookFallback then
                local p99Interval = math.max(1, tonumber(Config.AntiAFKP99PulseInterval) or 6.5)
                if now - (Runtime.Cache.LastP99AfkPulseAt or 0) >= p99Interval then
                    PulseP99AntiAfk()
                end
            end
            if Config.AntiAFK then
                local rbxInterval = math.max(10, tonumber(Config.AntiAFKRobloxPulseInterval) or 45)
                if Config.AntiAFKRoblox and (now - (Runtime.Cache.LastRobloxAfkPulseAt or 0)) >= rbxInterval then
                    PulseRobloxAntiAfk()
                end
                if Config.AntiAFKP99 and (now - (Runtime.Cache.LastP99SafeResetAt or 0)) >= rbxInterval then
                    Runtime.Helpers.PulseP99SafeIdleReset(curEnv.isMobile)
                end
            end
        end
    end)
end

local function DisableNativeAutoFarmOnce()
    local af = Modules.AutoFarmCmds
    if af and af.IsEnabled and af.Disable then
        local okE, enabled = pcall(af.IsEnabled)
        if okE and enabled == true then
            pcall(af.Disable)
        end
    end
end

local function ReleaseHeldPets()
    if not Modules.PlayerPet or not Modules.PlayerPet.GetByPlayer then
        return
    end
    local releasedAny = false
    pcall(function()
        for _, pet in pairs(Modules.PlayerPet.GetByPlayer(LocalPlayer)) do
            if pet and pet.AIHold == "PumpkinKaitun" then
                pet.AIHold = nil
                releasedAny = true
            end
        end
    end)
    if releasedAny and Modules.Signal and Modules.Signal.Fire then
        pcall(Modules.Signal.Fire, "PetAI_Reset")
    end
end

local ORIG_PET_SPEED_KEY = "_PumpkinTycoonKaitun_OrigCalcPetSpeed"
local HOOK_PET_SPEED_KEY = "_PumpkinTycoonKaitun_HookCalcPetSpeed"

local function RefreshLocalPetSpeeds(useOriginalCalc)
    local pp = Modules.PlayerPet
    if not pp or not pp.GetByPlayer then
        return 0
    end
    local okPets, pets = pcall(pp.GetByPlayer, LocalPlayer)
    if not okPets or type(pets) ~= "table" then
        return 0
    end

    local updated = 0
    local sampleMult = nil
    local targetMult = (not useOriginalCalc and Config.AutoBuffPetSpeed)
        and math.max(1, tonumber(Config.PetSpeedMultiplier) or 999)
        or nil

    for _, pet in pairs(pets) do
        if pet and not pet.destroyed then
            local mult = targetMult
            if not mult and type(pet.CalculateSpeedMultiplier) == "function" then
                local okM, calc = pcall(pet.CalculateSpeedMultiplier, pet)
                if okM and type(calc) == "number" and calc > 0 then
                    mult = calc
                end
            end
            if type(mult) == "number" and mult > 0 then
                sampleMult = mult
                if pet.speedMult ~= mult then
                    pet.speedMult = mult
                    updated = updated + 1
                end
                if pet.cpet and type(pet.cpet.Broadcast) == "function" then
                    local curIn = type(pet.cpet.parallelIn) == "table" and pet.cpet.parallelIn.petSpeedMult or nil
                    if curIn ~= mult then
                        pcall(pet.cpet.Broadcast, pet.cpet, "petSpeedMult", mult)
                    end
                end
            end
        end
    end
    if sampleMult ~= nil then
        Runtime.Stats.PetSpeedMult = sampleMult
    elseif targetMult ~= nil then
        Runtime.Stats.PetSpeedMult = targetMult
    end
    Runtime.Cache.LastPetSpeedRefreshAt = os.clock()
    return updated
end

local function RestorePetSpeedBuff()
    local pp = Modules.PlayerPet
    local env = getgenv()
    local orig = env[ORIG_PET_SPEED_KEY]
    local myWrapper = Runtime.Cache.PetSpeedHookWrapper
    if pp and type(orig) == "function" and (pp.CalculateSpeedMultiplier == myWrapper or pp.CalculateSpeedMultiplier == env[HOOK_PET_SPEED_KEY]) then
        local wasFrozen = type(table.isfrozen) == "function" and table.isfrozen(pp)
        if wasFrozen and type(setreadonly) == "function" then
            pcall(setreadonly, pp, false)
        end
        pcall(function()
            pp.CalculateSpeedMultiplier = orig
        end)
        if wasFrozen and type(setreadonly) == "function" then
            pcall(setreadonly, pp, true)
        end
    end
    if myWrapper ~= nil and env[HOOK_PET_SPEED_KEY] == myWrapper then
        env[HOOK_PET_SPEED_KEY] = nil
    end
    Runtime.Cache.PetSpeedHookActive = false
    Runtime.Cache.PetSpeedHookWrapper = nil
    Runtime.Cache.PetSpeedLastTargetMult = nil
    RefreshLocalPetSpeeds(true)
end

local function StepPetSpeedBuff()
    local pp = Modules.PlayerPet
    if not pp or type(pp.CalculateSpeedMultiplier) ~= "function" then
        return
    end
    local env = getgenv()
    local orig = env[ORIG_PET_SPEED_KEY]
    if type(orig) ~= "function" and pp.CalculateSpeedMultiplier ~= env[HOOK_PET_SPEED_KEY] then
        orig = pp.CalculateSpeedMultiplier
        env[ORIG_PET_SPEED_KEY] = orig
    end
    if type(orig) ~= "function" then
        return
    end

    if not Config.AutoBuffPetSpeed then
        if Runtime.Cache.PetSpeedHookActive or pp.CalculateSpeedMultiplier == env[HOOK_PET_SPEED_KEY] then
            RestorePetSpeedBuff()
        end
        return
    end

    if not Runtime.Cache.PetSpeedCreatedConnBound and pp.Created and pp.Created.Connect then
        Runtime.Cache.PetSpeedCreatedConnBound = true
        BindConn(pp.Created, function(pet)
            if not IsRunning() or not Config.AutoBuffPetSpeed then
                return
            end
            task.defer(function()
                if not IsRunning() or not Config.AutoBuffPetSpeed or not pet or pet.destroyed or pet.owner ~= LocalPlayer then
                    return
                end
                local targetMult = math.max(1, tonumber(Config.PetSpeedMultiplier) or 999)
                if pet.speedMult ~= targetMult then
                    pet.speedMult = targetMult
                end
                if pet.cpet and type(pet.cpet.Broadcast) == "function" then
                    local curIn = type(pet.cpet.parallelIn) == "table" and pet.cpet.parallelIn.petSpeedMult or nil
                    if curIn ~= targetMult then
                        pcall(pet.cpet.Broadcast, pet.cpet, "petSpeedMult", targetMult)
                    end
                end
                Runtime.Stats.PetSpeedMult = targetMult
            end)
        end)
    end

    local targetMult = math.max(1, tonumber(Config.PetSpeedMultiplier) or 999)
    local myWrapper = Runtime.Cache.PetSpeedHookWrapper
    local needAttach = (type(myWrapper) ~= "function")
        or (pp.CalculateSpeedMultiplier ~= myWrapper)
        or (not Runtime.Cache.PetSpeedHookActive)
    if needAttach then
        myWrapper = function(petSelf, ...)
            if IsRunning() and Config.AutoBuffPetSpeed and petSelf and petSelf.owner == LocalPlayer then
                local cfgMult = tonumber(Config.PetSpeedMultiplier)
                if cfgMult and cfgMult > 0 then
                    return cfgMult
                end
            end
            return orig(petSelf, ...)
        end
        env[HOOK_PET_SPEED_KEY] = myWrapper
        local wasFrozen = type(table.isfrozen) == "function" and table.isfrozen(pp)
        if wasFrozen and type(setreadonly) == "function" then
            pcall(setreadonly, pp, false)
        end
        local okSet = pcall(function()
            pp.CalculateSpeedMultiplier = myWrapper
        end)
        if wasFrozen and type(setreadonly) == "function" then
            pcall(setreadonly, pp, true)
        end
        if okSet then
            Runtime.Cache.PetSpeedHookWrapper = myWrapper
            Runtime.Cache.PetSpeedHookActive = true
            Runtime.Cache.PetSpeedLastTargetMult = targetMult
            Log("INFO", "Pet speed buff hook enabled (mult=%s).", tostring(targetMult))
            RefreshLocalPetSpeeds(false)
        end
        return
    end

    local now = os.clock()
    if Runtime.Cache.PetSpeedLastTargetMult ~= targetMult or (now - (Runtime.Cache.LastPetSpeedRefreshAt or 0)) >= 3.0 then
        Runtime.Cache.PetSpeedLastTargetMult = targetMult
        RefreshLocalPetSpeeds(false)
    end
end

-- ============================================================================
-- 3C. MAP & RENDER OPTIMIZER (METHOD B STRUCTURAL + CONDITIONAL BOUNDED 3D QUEUE)
-- ============================================================================
local SAFE_FLOOR_NAME = "_PumpkinKaitun_SafeFloor"
local OPTIMIZER_EVENT_ID = "PumpkinTycoon"
local WORLD_CLUTTER_NAMES = {
    ["PSX Portal"] = true,
    ["Border"] = true,
    ["PSX Hall"] = true,
    ["FlyBorder"] = true,
    ["GREYBOX_WIP"] = true,
    ["Tiles"] = true,
    ["__INSTANCE_SCENERY"] = true,
}
local DEBRIS_PRESERVE_NAMES = {
    PERSISTENT = true,
    TravelingMerchant = true,
    Currency = true,
    GREYBOX_WIP = true,
    Ragdolls = true,
    ASSETS = true,
}
local THINGS_CLEAR_FOLDERS = {
    "Ornaments",
    "Ski Chairs",
    "BalloonGifts",
    "Hoverboards",
    "InfinityEggs",
    "Flags",
    "VictoryScene",
    "__FAKE_INSTANCE_BREAK_ZONES",
}

local TrackedContainers = setmetatable({}, { __mode = "k" })
local HookedContainers = setmetatable({}, { __mode = "k" })

local function TrackContainer(container)
    if not container or TrackedContainers[container] then
        return
    end
    TrackedContainers[container] = true
    BindConn(container.Destroying, function()
        TrackedContainers[container] = nil
        HookedContainers[container] = nil
    end)
end

local function DestroyClutterInstance(inst, defer)
    if not inst or not inst.Parent or inst.Name == SAFE_FLOOR_NAME or inst == Workspace then
        return
    end
    Runtime.Stats.MapDestroyedCount = (Runtime.Stats.MapDestroyedCount or 0) + 1
    if defer then
        task.defer(function()
            if inst and inst.Parent then
                pcall(inst.Destroy, inst)
            end
        end)
    else
        pcall(inst.Destroy, inst)
    end
end

local function StripVisualObject(obj, stripCollision)
    if not obj or not obj.Parent or obj.Name == SAFE_FLOOR_NAME then
        return
    end
    if obj.Name == "Highlight" and obj.Parent and obj.Parent.Name == "RenderedEggs" then
        return
    end
    if obj:IsA("BasePart") then
        local changed = false
        if obj.Transparency < 1 then
            obj.Transparency = 1
            changed = true
        end
        if obj.CastShadow then
            obj.CastShadow = false
        end
        if obj.Material ~= Enum.Material.SmoothPlastic then
            obj.Material = Enum.Material.SmoothPlastic
        end
        if stripCollision then
            if obj.CanCollide then
                obj.CanCollide = false
            end
            if obj.CanTouch then
                obj.CanTouch = false
            end
            if obj.CanQuery then
                obj.CanQuery = false
            end
        end
        if changed then
            Runtime.Stats.VisualsHiddenCount = (Runtime.Stats.VisualsHiddenCount or 0) + 1
        end
        return
    end

    if obj:IsA("SurfaceAppearance") then
        Runtime.Stats.VisualsHiddenCount = (Runtime.Stats.VisualsHiddenCount or 0) + 1
        DestroyClutterInstance(obj, false)
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if obj.Transparency < 1 then
            obj.Transparency = 1
            Runtime.Stats.VisualsHiddenCount = (Runtime.Stats.VisualsHiddenCount or 0) + 1
        end
    elseif obj:IsA("ParticleEmitter") then
        if obj.Enabled or obj.Rate > 0 then
            obj.Enabled = false
            obj.Rate = 0
            Runtime.Stats.VisualsHiddenCount = (Runtime.Stats.VisualsHiddenCount or 0) + 1
        end
    elseif obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        if obj.Enabled then
            obj.Enabled = false
            Runtime.Stats.VisualsHiddenCount = (Runtime.Stats.VisualsHiddenCount or 0) + 1
        end
    elseif obj:IsA("Light") then
        if obj.Enabled or obj.Brightness > 0 then
            obj.Enabled = false
            obj.Brightness = 0
            Runtime.Stats.VisualsHiddenCount = (Runtime.Stats.VisualsHiddenCount or 0) + 1
        end
    elseif obj:IsA("Highlight") or obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
        if obj.Enabled then
            obj.Enabled = false
            Runtime.Stats.VisualsHiddenCount = (Runtime.Stats.VisualsHiddenCount or 0) + 1
        end
    end
end

local function StripLocalCharacterFx(charModel)
    if not charModel then
        return
    end
    for _, d in ipairs(charModel:GetDescendants()) do
        if d:IsA("BasePart") then
            if d.CastShadow then
                d.CastShadow = false
            end
        elseif d:IsA("ParticleEmitter") then
            d.Enabled = false
            d.Rate = 0
        elseif d:IsA("Trail") or d:IsA("Beam") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
            d.Enabled = false
        elseif d:IsA("Light") then
            d.Enabled = false
            d.Brightness = 0
        end
    end
end

function Runtime.Helpers.ClearVisualQueue()
    local q = Runtime.Cache.VisualStripQueue
    if type(q) ~= "table" then
        return
    end
    table.clear(q.items)
    table.clear(q.cols)
    table.clear(q.queued)
    q.head = 1
    q.tail = 0
end

function Runtime.Helpers.EnsureVisualStripHeartbeat()
    if Runtime.Cache.VisualStripHbBound then
        return
    end
    Runtime.Cache.VisualStripHbBound = true
    BindConn(RunService.Heartbeat, function()
        local q = Runtime.Cache.VisualStripQueue
        if not q or q.head > q.tail then
            return
        end
        if not IsRunning() or not Config.OptimizeMap or not Runtime.Cache.Is3dRenderingEnabled then
            Runtime.Helpers.ClearVisualQueue()
            return
        end

        local startAt = os.clock()
        local processed = 0
        local maxOps = 120
        while q.head <= q.tail and processed < maxOps do
            local idx = q.head
            local inst = q.items[idx]
            local stripCol = q.cols[idx] == true
            q.items[idx] = nil
            q.cols[idx] = nil
            q.head = idx + 1

            if inst and inst.Parent and inst.Name ~= SAFE_FLOOR_NAME then
                StripVisualObject(inst, stripCol)
                for _, child in ipairs(inst:GetChildren()) do
                    if not q.queued[child] and (q.tail - q.head + 1) < (q.maxSize or 2500) then
                        q.tail = q.tail + 1
                        q.items[q.tail] = child
                        q.cols[q.tail] = stripCol
                        q.queued[child] = true
                    end
                end
            end
            processed = processed + 1
            if processed >= 24 and (os.clock() - startAt) >= 0.0015 then
                break
            end
        end

        if q.head > q.tail then
            q.head = 1
            q.tail = 0
            table.clear(q.queued)
        end
    end)
end

function Runtime.Helpers.EnqueueVisualStrip(inst, stripCollision)
    if not IsRunning() or not Config.OptimizeMap or not Runtime.Cache.Is3dRenderingEnabled then
        return
    end
    if not inst or not inst.Parent or inst.Name == SAFE_FLOOR_NAME then
        return
    end
    local q = Runtime.Cache.VisualStripQueue
    if not q or q.queued[inst] then
        return
    end
    if (q.tail - q.head + 1) >= (q.maxSize or 2500) then
        return
    end
    Runtime.Helpers.EnsureVisualStripHeartbeat()
    q.tail = q.tail + 1
    q.items[q.tail] = inst
    q.cols[q.tail] = (stripCollision == true)
    q.queued[inst] = true
end

local function HookContainerChildAdded(container, stripCollision, isIslandsFolder)
    if not container or HookedContainers[container] then
        return
    end
    HookedContainers[container] = true
    local myUidStr = isIslandsFolder and tostring(LocalPlayer.UserId) or nil
    BindConn(container.ChildAdded, function(child)
        if not IsRunning() or not Config.OptimizeMap or not Runtime.Cache.Is3dRenderingEnabled then
            return
        end
        if isIslandsFolder then
            if not Config.HideIslandVisuals then
                return
            end
            local isMine = (child.Name == myUidStr)
            Runtime.Helpers.EnqueueVisualStrip(child, not isMine)
        else
            Runtime.Helpers.EnqueueVisualStrip(child, stripCollision)
        end
    end)
end

local function StripContainerTree(container, stripCollision, watchChildren, forceResweep)
    if not container or not container.Parent then
        return
    end
    if not Runtime.Cache.Is3dRenderingEnabled then
        return
    end
    local alreadyTracked = (TrackedContainers[container] == true)
    if alreadyTracked and not forceResweep then
        if watchChildren then
            HookContainerChildAdded(container, stripCollision, false)
        end
        return
    end

    TrackContainer(container)
    if watchChildren then
        HookContainerChildAdded(container, stripCollision, false)
    end
    Runtime.Helpers.EnqueueVisualStrip(container, stripCollision)
end

function Runtime.Helpers.SweepDebris(debrisFolder)
    local folder = debrisFolder or Workspace:FindFirstChild("__DEBRIS")
    if not folder or not folder.Parent then
        return
    end
    for _, child in ipairs(folder:GetChildren()) do
        if not child:IsA("Folder") and not DEBRIS_PRESERVE_NAMES[child.Name] and child.Name ~= SAFE_FLOOR_NAME then
            DestroyClutterInstance(child, false)
        end
    end
end

function Runtime.Helpers.ClearFolderChildrenOnce(folder)
    if not folder or not folder.Parent then
        return
    end
    for _, child in ipairs(folder:GetChildren()) do
        DestroyClutterInstance(child, false)
    end
end

local function ApplyLightingAndEffectsOptimization()
    if not Config.OptimizeLightingAndEffects then
        return
    end
    if not Runtime.Cache.SavedLightingState then
        local savedChildren = setmetatable({}, { __mode = "k" })
        for _, child in ipairs(Lighting:GetChildren()) do
            local entry = {}
            if child:IsA("PostEffect") then
                entry.Enabled = child.Enabled
            elseif child:IsA("Atmosphere") then
                entry.Density = child.Density
                entry.Offset = child.Offset
                entry.Glare = child.Glare
                entry.Haze = child.Haze
            elseif child:IsA("Sky") then
                entry.SkyboxBk = child.SkyboxBk
                entry.SkyboxDn = child.SkyboxDn
                entry.SkyboxFt = child.SkyboxFt
                entry.SkyboxLf = child.SkyboxLf
                entry.SkyboxRt = child.SkyboxRt
                entry.SkyboxUp = child.SkyboxUp
                entry.StarCount = child.StarCount
                entry.CelestialBodiesShown = child.CelestialBodiesShown
            elseif child:IsA("Clouds") then
                entry.Enabled = child.Enabled
                entry.Cover = child.Cover
            end
            if next(entry) ~= nil then
                savedChildren[child] = entry
            end
        end
        local prevQualityLevel = nil
        local prevSavedQuality = nil
        pcall(function()
            local r = settings and settings().Rendering
            if r then
                prevQualityLevel = r.QualityLevel
                r.QualityLevel = Enum.QualityLevel.Level01
            end
        end)
        pcall(function()
            local userSettings = UserSettings()
            local ugs = userSettings and userSettings:GetService("UserGameSettings")
            if ugs then
                prevSavedQuality = ugs.SavedQualityLevel
                if ugs.SavedQualityLevel ~= Enum.SavedQualitySetting.QualityLevel1 then
                    ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
                end
            end
        end)

        Runtime.Cache.SavedLightingState = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            Brightness = Lighting.Brightness,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
            RenderQualityLevel = prevQualityLevel,
            SavedQualityLevel = prevSavedQuality,
            Children = savedChildren,
        }

        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            pcall(function()
                terrain.Decoration = false
            end)
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            pcall(function()
                terrain:Clear()
            end)
        end
    end

    if Lighting.GlobalShadows then
        Lighting.GlobalShadows = false
    end
    if Lighting.Brightness ~= 0 then
        Lighting.Brightness = 0
    end
    if Lighting.FogEnd < 9e8 then
        Lighting.FogEnd = 9e9
    end
    if Lighting.EnvironmentDiffuseScale ~= 0 then
        Lighting.EnvironmentDiffuseScale = 0
    end
    if Lighting.EnvironmentSpecularScale ~= 0 then
        Lighting.EnvironmentSpecularScale = 0
    end

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostEffect") then
            if child.Enabled then
                child.Enabled = false
            end
        elseif child:IsA("Atmosphere") then
            child.Density = 0
            child.Offset = 0
            child.Glare = 0
            child.Haze = 0
        elseif child:IsA("Sky") then
            child.SkyboxBk = ""
            child.SkyboxDn = ""
            child.SkyboxFt = ""
            child.SkyboxLf = ""
            child.SkyboxRt = ""
            child.SkyboxUp = ""
            child.StarCount = 0
            child.CelestialBodiesShown = false
        elseif child:IsA("Clouds") then
            child.Enabled = false
            child.Cover = 0
        end
    end
end

local function CleanOtherPlayerCharacter(model)
    if not Runtime.Cache.Is3dRenderingEnabled or not model or model == LocalPlayer.Character or not model:IsA("Model") then
        return
    end
    local plr = Players:GetPlayerFromCharacter(model)
    local isOtherChar = (plr ~= nil and plr ~= LocalPlayer)
        or (model.Name ~= LocalPlayer.Name and model:FindFirstChildOfClass("Humanoid") ~= nil)
    if isOtherChar then
        StripContainerTree(model, true, false, false)
    end
end

local function StripIslandsFolder(islands)
    if not islands or not Runtime.Cache.Is3dRenderingEnabled then
        return
    end
    local myUidStr = tostring(LocalPlayer.UserId)
    for _, islandModel in ipairs(islands:GetChildren()) do
        if not TrackedContainers[islandModel] then
            local isMine = (islandModel.Name == myUidStr)
            StripContainerTree(islandModel, not isMine, false, false)
        end
    end
    HookContainerChildAdded(islands, false, true)
end

local function EnsureSafeFloor(plot)
    if not Config.OptimizeMap or not Config.SafeFloorEnabled then
        local existing = Runtime.Cache.SafeFloorPart or Workspace:FindFirstChild(SAFE_FLOOR_NAME)
        if existing and existing.Parent then
            pcall(existing.Destroy, existing)
        end
        Runtime.Cache.SafeFloorPart = nil
        return
    end
    if not plot then
        return
    end
    local okCf, cf = pcall(plot.GetCFrame, plot)
    if not okCf or typeof(cf) ~= "CFrame" then
        return
    end

    local floor = Runtime.Cache.SafeFloorPart
    if not floor or not floor.Parent then
        floor = Workspace:FindFirstChild(SAFE_FLOOR_NAME)
    end
    if not floor or not floor:IsA("Part") then
        local newFloor = Instance.new("Part")
        newFloor.Name = SAFE_FLOOR_NAME
        newFloor.Anchored = true
        newFloor.CanCollide = true
        newFloor.CanQuery = true
        newFloor.CanTouch = false
        newFloor.Transparency = 1
        newFloor.CastShadow = false
        newFloor.Material = Enum.Material.SmoothPlastic
        newFloor.Size = Vector3.new(2048, 4, 2048)
        newFloor.Parent = Workspace
        floor = newFloor
    end
    Runtime.Cache.SafeFloorPart = floor

    local targetPos = Vector3.new(cf.Position.X, cf.Position.Y - 12, cf.Position.Z)
    if (floor.Position - targetPos).Magnitude > 1 then
        floor.CFrame = CFrame.new(targetPos)
    end
end

function Runtime.Helpers.ApplyUltraLowRamSettings()
    if not Config.UltraLowRAM or Runtime.Cache.UltraLowRamApplied then
        return
    end
    Runtime.Cache.UltraLowRamApplied = true
    if Modules.Variables then
        if Runtime.Cache.PrevPotatoMode == nil then
            Runtime.Cache.PrevPotatoMode = Modules.Variables.PotatoMode
        end
        Modules.Variables.PotatoMode = true
    end
    local needReduceOrbs = false
    local sc = Modules.SettingsCmds
    if sc and type(sc.Get) == "function" and type(sc.GetValue) == "function" then
        local okG, valStr = pcall(sc.Get, "ReduceOrbs")
        local okV, valNum = pcall(sc.GetValue, "ReduceOrbs")
        if (not okG or valStr ~= "On") and (not okV or valNum ~= 1) then
            needReduceOrbs = true
        end
    elseif Modules.Save and Modules.Save.Get then
        local okS, saveData = pcall(Modules.Save.Get)
        local cur = okS and type(saveData) == "table" and saveData.Settings and saveData.Settings.ReduceOrbs
        if cur ~= 1 then
            needReduceOrbs = true
        end
    end
    if needReduceOrbs and Modules.Network and type(Modules.Network.Invoke) == "function" then
        task.spawn(function()
            pcall(Modules.Network.Invoke, "Toggle Setting", "ReduceOrbs")
        end)
    end
end

local function RunMapOptimizerPass(plot)
    if not Config.OptimizeMap then
        return
    end
    local inEvent = (plot ~= nil) or (Runtime.Helpers.IsInEventInstance and Runtime.Helpers.IsInEventInstance())
    if not inEvent then
        return
    end

    local is3dOn = (Runtime.Cache.Is3dRenderingEnabled == true)
    local things = Workspace:FindFirstChild("__THINGS")

    if Config.StripWorldClutter or (is3dOn and Config.HideEntityVisuals) then
        for _, child in ipairs(Workspace:GetChildren()) do
            if Config.StripWorldClutter and WORLD_CLUTTER_NAMES[child.Name] then
                DestroyClutterInstance(child, false)
            elseif is3dOn and Config.HideEntityVisuals and child:IsA("Model") and not TrackedContainers[child] then
                CleanOtherPlayerCharacter(child)
            end
        end
    end

    if Config.StripWorldClutter then
        Runtime.Helpers.SweepDebris(Workspace:FindFirstChild("__DEBRIS"))
        Runtime.Cache.LastDebrisSweepAt = os.clock()

        if things then
            for _, folderName in ipairs(THINGS_CLEAR_FOLDERS) do
                Runtime.Helpers.ClearFolderChildrenOnce(things:FindFirstChild(folderName))
            end

            if Config.UltraLowRAM then
                for _, subName in ipairs({ "Eggs", "ShinyRelics", "ZoneEggs" }) do
                    local subFolder = things:FindFirstChild(subName)
                    if subFolder and not TrackedContainers[subFolder] then
                        TrackContainer(subFolder)
                        Runtime.Helpers.ClearFolderChildrenOnce(subFolder)
                    end
                end
            end

            local ic = things:FindFirstChild("__INSTANCE_CONTAINER")
            local activeFolder = ic and ic:FindFirstChild("Active")
            local ptActive = activeFolder and activeFolder:FindFirstChild(OPTIMIZER_EVENT_ID)
            if ptActive then
                local water = ptActive:FindFirstChild("Water")
                if water then
                    DestroyClutterInstance(water, false)
                end
                if not HookedContainers[ptActive] then
                    HookedContainers[ptActive] = true
                    BindConn(ptActive.ChildAdded, function(child)
                        if IsRunning() and Config.OptimizeMap and Config.StripWorldClutter and child.Name == "Water" then
                            task.defer(DestroyClutterInstance, child, false)
                        end
                    end)
                end
            end
        end
    end

    if is3dOn then
        if Config.HideIslandVisuals then
            StripIslandsFolder(Workspace:FindFirstChild("PumpkinTycoonIslands"))
            if things then
                StripContainerTree(things:FindFirstChild("Plots"), false, true, false)
            end
            StripContainerTree(Workspace:FindFirstChild("PumpkinTycoonPads"), false, true, false)
            StripContainerTree(Workspace:FindFirstChild("PumpkinTycoonPumpkins"), false, true, false)
        end

        if Config.HideEntityVisuals and things then
            for _, entityFolderName in ipairs({ "Breakables", "CustomEggs", "Pets", "PetsHidden", "Orbs" }) do
                StripContainerTree(things:FindFirstChild(entityFolderName), false, true, false)
            end
        end
    end

    EnsureSafeFloor(plot)
    Runtime.Cache.MapClutterClearedInEvent = true
end

local function HookOtherPlayerEvents(plr)
    if not plr or plr == LocalPlayer then
        return
    end
    local charConns = Runtime.Cache.PlayerCharConns
    if charConns[plr] then
        pcall(charConns[plr].Disconnect, charConns[plr])
        charConns[plr] = nil
    end
    if plr.Character and Runtime.Cache.Is3dRenderingEnabled and Config.OptimizeMap and Config.HideEntityVisuals then
        CleanOtherPlayerCharacter(plr.Character)
    end
    charConns[plr] = BindConn(plr.CharacterAdded, function(char)
        if IsRunning() and Config.OptimizeMap and Config.HideEntityVisuals and Runtime.Cache.Is3dRenderingEnabled then
            Runtime.Helpers.EnqueueVisualStrip(char, true)
        end
    end)
end

local function SetupMapOptimizer()
    if not Config.OptimizeMap then
        return
    end
    if Config.UltraLowRAM then
        Runtime.Helpers.ApplyUltraLowRamSettings()
    end
    if not Runtime.Cache.MapOptimizerInitialized then
        Runtime.Cache.MapOptimizerInitialized = true
        ApplyLightingAndEffectsOptimization()
        local myChar = LocalPlayer.Character
        if myChar and Config.OptimizeLightingAndEffects then
            StripLocalCharacterFx(myChar)
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            HookOtherPlayerEvents(plr)
        end
        BindConn(Players.PlayerAdded, HookOtherPlayerEvents)
        BindConn(Players.PlayerRemoving, function(plr)
            local charConns = Runtime.Cache.PlayerCharConns
            local c = charConns and charConns[plr]
            if c then
                pcall(c.Disconnect, c)
                charConns[plr] = nil
            end
        end)

        BindConn(Workspace.ChildAdded, function(child)
            if not IsRunning() or not Config.OptimizeMap or not child then
                return
            end
            local inEvent = Runtime.Helpers.IsInEventInstance and Runtime.Helpers.IsInEventInstance()
            if not inEvent then
                return
            end
            if Config.StripWorldClutter and WORLD_CLUTTER_NAMES[child.Name] then
                task.defer(DestroyClutterInstance, child, false)
                return
            end
            if not Runtime.Cache.Is3dRenderingEnabled then
                return
            end
            if Config.HideIslandVisuals and child.Name == "PumpkinTycoonIslands" then
                StripIslandsFolder(child)
            elseif Config.HideIslandVisuals and (child.Name == "PumpkinTycoonPads" or child.Name == "PumpkinTycoonPumpkins") then
                StripContainerTree(child, false, true, false)
            elseif Config.HideEntityVisuals and child:IsA("Model") then
                CleanOtherPlayerCharacter(child)
            end
        end)

        BindConn(Lighting.ChildAdded, function()
            if IsRunning() and Config.OptimizeMap and Config.OptimizeLightingAndEffects then
                task.defer(ApplyLightingAndEffectsOptimization)
            end
        end)

        BindConn(LocalPlayer.CharacterAdded, function(char)
            if IsRunning() and Config.OptimizeMap and Config.OptimizeLightingAndEffects then
                task.defer(StripLocalCharacterFx, char)
            end
        end)
    end

    if Runtime.Helpers.IsInEventInstance and Runtime.Helpers.IsInEventInstance() then
        task.spawn(function()
            RunMapOptimizerPass(nil)
            Runtime.Cache.LastOptimizeScanAt = os.clock()
            Log("INFO", "Map optimizer active (3dOn=%s, destroyed=%d, visualsHidden=%d).",
                tostring(Runtime.Cache.Is3dRenderingEnabled == true),
                tonumber(Runtime.Stats.MapDestroyedCount) or 0,
                tonumber(Runtime.Stats.VisualsHiddenCount) or 0)
        end)
    else
        Log("INFO", "Map optimizer armed (3dOn=%s); clutter pass deferred until PumpkinTycoon.",
            tostring(Runtime.Cache.Is3dRenderingEnabled == true))
    end
end

local function ScheduleMyIslandResweep()
    if not Runtime.Cache.Is3dRenderingEnabled or not Config.OptimizeMap or not Config.HideIslandVisuals then
        return
    end
    local token = (Runtime.Cache.MyIslandResweepToken or 0) + 1
    Runtime.Cache.MyIslandResweepToken = token
    task.delay(0.85, function()
        if not IsRunning() or Runtime.Cache.MyIslandResweepToken ~= token then
            return
        end
        if not Config.OptimizeMap or not Config.HideIslandVisuals or not Runtime.Cache.Is3dRenderingEnabled then
            return
        end
        local islands = Workspace:FindFirstChild("PumpkinTycoonIslands")
        local myDecor = islands and islands:FindFirstChild(tostring(LocalPlayer.UserId))
        if myDecor then
            Runtime.Helpers.EnqueueVisualStrip(myDecor, false)
        end
    end)
end

function Runtime.Helpers.On3dRenderingChanged(active)
    if not IsRunning() then
        return
    end
    if not active then
        Runtime.Helpers.ClearVisualQueue()
        Runtime.Cache.MyIslandResweepToken = (Runtime.Cache.MyIslandResweepToken or 0) + 1
        return
    end
    if Config.OptimizeMap and Runtime.Helpers.IsInEventInstance and Runtime.Helpers.IsInEventInstance() then
        table.clear(TrackedContainers)
        RunMapOptimizerPass(nil)
    end
end

local function StepMapOptimizer(plot)
    if not Config.OptimizeMap then
        return
    end
    EnsureSafeFloor(plot)

    local now = os.clock()
    if not Runtime.Cache.MapClutterClearedInEvent then
        Runtime.Cache.LastOptimizeScanAt = now
        RunMapOptimizerPass(plot)
        Log("INFO", "Map optimizer entered %s (3dOn=%s, destroyed=%d, visualsHidden=%d).",
            OPTIMIZER_EVENT_ID,
            tostring(Runtime.Cache.Is3dRenderingEnabled == true),
            tonumber(Runtime.Stats.MapDestroyedCount) or 0,
            tonumber(Runtime.Stats.VisualsHiddenCount) or 0)
        return
    end

    if Runtime.Cache.Is3dRenderingEnabled then
        local buttonsDone = tonumber(Runtime.Stats.ButtonsDone) or 0
        local prevButtonsDone = tonumber(Runtime.Cache.LastButtonsDoneForDecor) or -1
        if buttonsDone ~= prevButtonsDone then
            Runtime.Cache.LastButtonsDoneForDecor = buttonsDone
            if prevButtonsDone >= 0 then
                ScheduleMyIslandResweep()
            end
        end
    end

    if Config.StripWorldClutter and (now - (Runtime.Cache.LastDebrisSweepAt or 0)) >= 2.5 then
        Runtime.Cache.LastDebrisSweepAt = now
        Runtime.Helpers.SweepDebris(Workspace:FindFirstChild("__DEBRIS"))
    end

    if (now - (Runtime.Cache.LastConnPruneAt or 0)) >= 15.0 then
        Runtime.Cache.LastConnPruneAt = now
        Runtime.Helpers.PruneConnections()
    end

    local interval = math.max(5.0, tonumber(Config.OptimizeScanInterval) or 15.0)
    if now - (Runtime.Cache.LastOptimizeScanAt or 0) >= interval then
        Runtime.Cache.LastOptimizeScanAt = now
        RunMapOptimizerPass(plot)
    end
end

local function RestoreMapOptimizer()
    Runtime.Helpers.ClearVisualQueue()
    Runtime.Cache.MyIslandResweepToken = (Runtime.Cache.MyIslandResweepToken or 0) + 1
    if Runtime.Cache.PrevPotatoMode ~= nil and Modules.Variables then
        Modules.Variables.PotatoMode = Runtime.Cache.PrevPotatoMode
        Runtime.Cache.PrevPotatoMode = nil
    end
    Runtime.Cache.UltraLowRamApplied = false
    Runtime.Cache.MapClutterClearedInEvent = false

    local charConns = Runtime.Cache.PlayerCharConns
    if type(charConns) == "table" then
        for _, c in pairs(charConns) do
            if c then
                pcall(c.Disconnect, c)
            end
        end
        table.clear(charConns)
    end

    local safeFloor = Runtime.Cache.SafeFloorPart or Workspace:FindFirstChild(SAFE_FLOOR_NAME)
    if safeFloor and safeFloor.Parent then
        pcall(safeFloor.Destroy, safeFloor)
    end
    Runtime.Cache.SafeFloorPart = nil

    local saved = Runtime.Cache.SavedLightingState
    if type(saved) == "table" then
        pcall(function()
            Lighting.GlobalShadows = saved.GlobalShadows
            Lighting.FogEnd = saved.FogEnd
            Lighting.Brightness = saved.Brightness
            Lighting.EnvironmentDiffuseScale = saved.EnvironmentDiffuseScale
            Lighting.EnvironmentSpecularScale = saved.EnvironmentSpecularScale
        end)
        if saved.RenderQualityLevel ~= nil then
            pcall(function()
                local r = settings and settings().Rendering
                if r then
                    r.QualityLevel = saved.RenderQualityLevel
                end
            end)
        end
        if saved.SavedQualityLevel ~= nil then
            pcall(function()
                local userSettings = UserSettings()
                local ugs = userSettings and userSettings:GetService("UserGameSettings")
                if ugs then
                    ugs.SavedQualityLevel = saved.SavedQualityLevel
                end
            end)
        end
        if type(saved.Children) == "table" then
            for inst, props in pairs(saved.Children) do
                if inst and inst.Parent then
                    pcall(function()
                        for k, v in pairs(props) do
                            (inst :: any)[k] = v
                        end
                    end)
                end
            end
        end
        Runtime.Cache.SavedLightingState = nil
    end
    table.clear(TrackedContainers)
    table.clear(HookedContainers)
    Runtime.Cache.MapOptimizerInitialized = false
end

Runtime.Teardown = function()
    Runtime.Running = false
    for _, conn in ipairs(Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(Connections)
    CleanupKaitunDashboard()
    RestorePetSpeedBuff()
    RestoreAntiAfkNetworkHook()
    RestoreMapOptimizer()
    ReleaseHeldPets()
    Runtime.Cache.PlotSavePlot = nil
    table.clear(Runtime.Cache.PlotSaveEntries)
    table.clear(Runtime.Cache.PlotSaveConnsBound)
    Runtime.Cache.PedInfoCache = nil
    Runtime.Cache.TapTargets = nil
    table.clear(Runtime.Cache.TargetEggCache)
    Runtime.Cache.MachineSessionDepth = 0
    Runtime.Cache.HatchYieldUntil = 0
    Runtime.Cache.HatchInFlight = false
    Runtime.Cache.MoveLockUntil = 0
    Runtime.Cache.SightingHookBound = false
    Runtime.Cache.ActiveSighting = nil
    Runtime.Cache.NetStoreShelfCache = nil
    Runtime.Cache.TurkeyBossActiveEndsAt = 0
    Runtime.Cache.TurkeyBossEngagedAt = 0
    Runtime.Cache.TurkeyBossSkippedEndsAt = 0
    Runtime.Cache.TurkeyBossReturnPos = nil
    Runtime.Cache.TurkeyBossLastHealth = nil
    Runtime.Stats.FightingTurkeyBoss = false
    Runtime.Stats.TurkeyBossShare = 0
    Runtime.Stats.TurkeyBossHealth = 0
    Runtime.Stats.TurkeyBossMaxHealth = 0
    if type(Runtime.Cache.WildSlotCooldown) == "table" then
        table.clear(Runtime.Cache.WildSlotCooldown)
    end
    Log("INFO", "Previous session cleaned up.")
end
getgenv()[GEN_KEY] = Runtime

-- ============================================================================
-- 4. CORE HELPER UTILITIES
-- ============================================================================
local PT = Modules.PumpkinTycoon
local INSTANCE_ID = (PT and PT.INSTANCE_ID) or "PumpkinTycoon"
local NET = (PT and PT.NET) or {
    Buy = "NZ_Commit",
    BuyBand = "FZ_Reserve",
    BuyNet = "ZK_Barter",
    Cannon = "TC_Launch",
    CatchSighting = "PV_Glimpse",
    CatchWild = "RU_Ensnare",
    CocoaBuyTime = "VB_Extend",
    Complete = "BT_Settle",
    Complete2 = "MH_Conclude",
    GiftOpen = "YR_Hydrate",
    NetShelf = "QS_Survey",
    PlaceStock = "XC_Allocate",
    Rebirth = "EW_Renew",
    SetAutoBreak = "QW_Policy",
    SetAutoMerchant = "HM_Sustain",
    SetAutoNets = "GN_Restock",
    SetAutoPlace = "JD_Prefer",
    SetHunt = "LF_Pursue",
    SetLock = "KT_Shelter",
    TutorialDone = "WL_Recall",
    UpgradeBuy = "OQ_Advance",
}
local VAR = (PT and PT.VAR) or {
    Buttons = "Buttons",
    Pedestals = "Pedestals",
    Stock = "Stock",
    Merchant = "Merchant",
    AutoBreak = "AutoBreak",
    Tutorial = "Tutorial",
    Rebirths = "Rebirths",
    CannonEver = "CannonEver",
    Wild = "Wild",
    Hunt = "Hunt",
}

local function GetCharacter()
    local char = LocalPlayer.Character
    local hrp = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
    return char, hrp
end

local function WaitReady()
    local startAt = os.clock()
    local lastLogAt = 0

    while IsRunning() do
        local _, hrp = GetCharacter()
        local loadedAttr = LocalPlayer:GetAttribute("__LOADED") == true
        local hasGui = LocalPlayer:FindFirstChild("PlayerGui") ~= nil
        local saveOk, saveData = pcall(function()
            return Modules.Save and Modules.Save.Get and Modules.Save.Get()
        end)

        if loadedAttr and hasGui and hrp and saveOk and type(saveData) == "table" then
            return true
        end

        local elapsed = os.clock() - startAt
        if (lastLogAt == 0 and elapsed >= 2) or (lastLogAt > 0 and elapsed - lastLogAt >= 15) then
            lastLogAt = elapsed
            local missing = not loadedAttr and "LocalPlayer.__LOADED"
                or (not hasGui and "PlayerGui")
                or (not hrp and "HumanoidRootPart")
                or "SaveData"
            Log("INFO", "Waiting for character and player data (stage=%s, elapsed=%.1fs)...", missing, elapsed)
        end
        task.wait(0.25)
    end
    return false
end

local function HorizontalDist(a, b)
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

local function MoveNear(targetPos, minThreshold)
    local _, hrp = GetCharacter()
    if not hrp or not targetPos then
        return false
    end
    local dist = HorizontalDist(hrp.Position, targetPos)
    if dist <= (minThreshold or 14) then
        return true
    end
    -- Offset cleanly on the same Y+2 plane to avoid lodging inside models
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 2.5, 4))
    Runtime.Cache.LastTeleportAt = os.clock()
    return true
end

local function IsMoveLocked()
    return (Runtime.Cache.MoveLockUntil or 0) > os.clock()
end

local function AcquireMoveLock(durationSec)
    local untilTs = os.clock() + (tonumber(durationSec) or 3.0)
    if untilTs > (Runtime.Cache.MoveLockUntil or 0) then
        Runtime.Cache.MoveLockUntil = untilTs
    end
end

local function ReleaseMoveLock()
    Runtime.Cache.MoveLockUntil = 0
end

--- Close a machine UI modal only when TabController confirms that specific machine tab is open.
local function CloseMachineTab(machineName)
    local tc = Modules.TabController
    if not tc or type(machineName) ~= "string" then
        return
    end
    if type(tc.IsOpen) ~= "function" or type(tc.CloseTab) ~= "function" then
        return
    end
    local okOpen, isOpen = pcall(tc.IsOpen, machineName)
    if okOpen and isOpen == true then
        pcall(tc.CloseTab)
    end
end

--- Acquire a nested machine session lock and pause active AutoHatch cleanly before moving.
local function BeginMachineSession(waitTimeoutSec)
    Runtime.Cache.MachineSessionDepth = (Runtime.Cache.MachineSessionDepth or 0) + 1
    local lockSec = 4.0
    Runtime.Cache.HatchYieldUntil = math.max(Runtime.Cache.HatchYieldUntil or 0, os.clock() + lockSec)
    AcquireMoveLock(lockSec)

    if Runtime.Cache.MachineSessionDepth == 1 then
        local deadline = os.clock() + (tonumber(waitTimeoutSec) or 1.5)
        while IsRunning() and Runtime.Cache.HatchInFlight and os.clock() < deadline do
            Runtime.Cache.HatchYieldUntil = math.max(Runtime.Cache.HatchYieldUntil or 0, os.clock() + lockSec)
            AcquireMoveLock(lockSec)
            task.wait(0.03)
        end
    end
end

--- Extend both MoveLock and HatchYieldUntil during multi-invoke machine batches.
local function ExtendMachineSession(lockSec)
    local dur = tonumber(lockSec) or 4.0
    if (Runtime.Cache.MachineSessionDepth or 0) > 0 then
        Runtime.Cache.HatchYieldUntil = math.max(Runtime.Cache.HatchYieldUntil or 0, os.clock() + dur)
    end
    AcquireMoveLock(dur)
end

local function EndMachineSession()
    local depth = math.max(0, (Runtime.Cache.MachineSessionDepth or 1) - 1)
    Runtime.Cache.MachineSessionDepth = depth
    if depth == 0 then
        Runtime.Cache.HatchYieldUntil = 0
        ReleaseMoveLock()
    end
end

--- Run a callback across one or more machine visits while holding MoveLock and pausing AutoHatch.
local function WithMachineSession(callback)
    BeginMachineSession(1.5)
    local ok, err = pcall(callback)
    EndMachineSession()
    if not ok then
        Log("DEBUG", "Machine session error: %s", tostring(err))
        return false
    end
    return true
end

local function EnsureNearMachinePad(plot, machineName, rangeFn, standOnPad)
    if not plot or not machineName or not Modules.PumpkinButtonsUtil or not Modules.PumpkinButtonsUtil.MachinePad then
        return false
    end
    local okPlot, plotModel = pcall(plot.GetModel, plot)
    if not okPlot or not plotModel then
        return false
    end
    local pad = Modules.PumpkinButtonsUtil.MachinePad(plotModel, machineName)
    if not pad or not pad:IsA("BasePart") then
        return false
    end
    local range = 20
    if type(rangeFn) == "number" and rangeFn >= 6 then
        range = rangeFn
    elseif type(rangeFn) == "function" then
        local okR, r = pcall(rangeFn)
        if okR and type(r) == "number" and r >= 6 then
            range = r
        end
    end
    local moveDist = standOnPad and 2.5 or math.clamp(range - 8, 4, 12)
    local _, hrp = GetCharacter()
    if not hrp then
        return false
    end
    ExtendMachineSession(4.0)
    local needMove = HorizontalDist(hrp.Position, pad.Position) > moveDist
        or math.abs(hrp.Position.Y - pad.Position.Y) > 6
    if standOnPad and Modules.MachineCmds and Modules.MachineCmds.IsStandingOn then
        local okOn, standing = pcall(Modules.MachineCmds.IsStandingOn, machineName)
        if okOn and standing == false then
            needMove = true
        end
    end
    if needMove then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
        end)
        local targetOffset = standOnPad
            and Vector3.new(0, (pad.Size.Y * 0.5) + 2.8, 0)
            or Vector3.new(0, 2.5, 1.5)
        hrp.CFrame = CFrame.new(pad.Position + targetOffset)
        Runtime.Cache.LastTeleportAt = os.clock()
    end
    local waitLeft = 0.38 - (os.clock() - (Runtime.Cache.LastTeleportAt or 0))
    if waitLeft > 0 then
        task.wait(waitLeft)
    end
    _, hrp = GetCharacter()
    if not hrp or (hrp.Position - pad.Position).Magnitude > (range - 1) then
        return false
    end
    return true
end

local function WithMachinePad(plot, machineName, rangeFn, callback, opts)
    BeginMachineSession(1.5)
    local standOnPad = type(opts) == "table" and opts.standOnPad == true
    local closeModal = type(opts) == "table" and opts.closeModal == true
    if not EnsureNearMachinePad(plot, machineName, rangeFn, standOnPad) then
        EndMachineSession()
        return false
    end
    if closeModal then
        CloseMachineTab(machineName)
    end
    local ok, err = pcall(callback)
    if closeModal then
        CloseMachineTab(machineName)
        task.delay(0.2, function()
            if IsRunning() then
                CloseMachineTab(machineName)
            end
        end)
    end
    EndMachineSession()
    if not ok then
        Log("DEBUG", "Machine action error [%s]: %s", tostring(machineName), tostring(err))
        return false
    end
    return true
end

local function GetCurrency(currencyId)
    if Modules.CurrencyCmds and Modules.CurrencyCmds.Get then
        local ok, val = pcall(Modules.CurrencyCmds.Get, currencyId)
        if ok and type(val) == "number" then
            return val
        end
    end
    return 0
end

Runtime.Helpers = Runtime.Helpers or {}

function Runtime.Helpers.RecordCoinsSpent(amount)
    local amt = tonumber(amount)
    if amt and amt > 0 then
        Runtime.Cache.TrackedCoinsSpent = (Runtime.Cache.TrackedCoinsSpent or 0) + amt
    end
end

function Runtime.Helpers.GetWindowCps(lookbackSec)
    local samples = Runtime.Cache.CoinRateSamples
    if type(samples) ~= "table" or #samples < 2 then
        return 0, 0
    end
    local latest = samples[#samples]
    local cutoff = latest.t - math.max(1, tonumber(lookbackSec) or 60)
    local base = samples[1]
    for i = #samples, 1, -1 do
        local s = samples[i]
        if s.t <= cutoff then
            base = s
            break
        end
        base = s
    end
    local dt = latest.t - base.t
    if dt < 1 then
        return 0, dt
    end
    return math.max(0, (latest.cum - base.cum) / dt), dt
end

function Runtime.Helpers.UpdateCoinRateSampler(coinsOverride)
    local now = os.clock()
    if Runtime.Cache.CoinRateSamples and #Runtime.Cache.CoinRateSamples > 0 and (now - (Runtime.Cache.LastCoinRateSampleAt or 0)) < 1.0 then
        return tonumber(Runtime.Stats.CoinsPerSec) or 0
    end
    Runtime.Cache.LastCoinRateSampleAt = now
    local coins = tonumber(coinsOverride) or GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
    local gross = coins + (Runtime.Cache.TrackedCoinsSpent or 0)
    if Runtime.Cache.LastGrossCoins == nil then
        Runtime.Cache.LastGrossCoins = gross
        Runtime.Cache.CumulativeCoinsEarned = 0
    else
        local delta = gross - Runtime.Cache.LastGrossCoins
        if delta > 0 then
            Runtime.Cache.CumulativeCoinsEarned = (Runtime.Cache.CumulativeCoinsEarned or 0) + delta
        end
        Runtime.Cache.LastGrossCoins = gross
    end
    local samples = Runtime.Cache.CoinRateSamples
    if type(samples) ~= "table" then
        samples = {}
        Runtime.Cache.CoinRateSamples = samples
    end
    table.insert(samples, { t = now, cum = Runtime.Cache.CumulativeCoinsEarned or 0 })
    while #samples > 2 and (now - samples[1].t) > 65 do
        table.remove(samples, 1)
    end
    local cps = select(1, Runtime.Helpers.GetWindowCps(60))
    Runtime.Stats.CoinsPerSec = cps
    return cps
end

function Runtime.Helpers.IsIncomeSustainedForCocoa(minCps)
    Runtime.Helpers.UpdateCoinRateSampler()
    local minSampleSec = math.max(10, tonumber(Config.CocoaIncomeMinSampleSec) or 45)
    local longCps, longSpan = Runtime.Helpers.GetWindowCps(60)
    local shortCps, shortSpan = Runtime.Helpers.GetWindowCps(20)
    if longSpan < minSampleSec or shortSpan < 10 then
        return false, longCps
    end
    return (longCps >= minCps and shortCps >= (minCps * 0.85)), longCps
end

function Runtime.Helpers.InvalidatePlotSave(plot, key)
    if not plot or (Runtime.Cache.PlotSavePlot ~= nil and Runtime.Cache.PlotSavePlot ~= plot) then
        Runtime.Cache.PlotSavePlot = nil
        table.clear(Runtime.Cache.PlotSaveEntries)
        table.clear(Runtime.Cache.PlotSaveConnsBound)
        Runtime.Cache.PedInfoCache = nil
        Runtime.Cache.PedInfoVer = -1
        return
    end
    local entries = Runtime.Cache.PlotSaveEntries
    if key ~= nil then
        local entry = entries[key]
        if entry then
            entry.dirty = true
            entry.at = 0
            entry.ver = (entry.ver or 0) + 1
        end
        if key == VAR.Pedestals then
            Runtime.Cache.PedInfoCache = nil
        elseif key == VAR.Buttons then
            table.clear(Runtime.Cache.TargetEggCache)
        end
    else
        for _, entry in pairs(entries) do
            entry.dirty = true
            entry.at = 0
            entry.ver = (entry.ver or 0) + 1
        end
        Runtime.Cache.PedInfoCache = nil
        table.clear(Runtime.Cache.TargetEggCache)
    end
end

function Runtime.Helpers.GetPlotSave(plot, key, forceRefresh)
    if not plot or type(key) ~= "string" then
        return nil, 0
    end
    if Runtime.Cache.PlotSavePlot ~= plot then
        Runtime.Cache.PlotSavePlot = plot
        table.clear(Runtime.Cache.PlotSaveEntries)
        table.clear(Runtime.Cache.PlotSaveConnsBound)
        Runtime.Cache.PedInfoCache = nil
        Runtime.Cache.PedInfoVer = -1
        Runtime.Cache.TutorialDonePlot = nil
        if plot.Destroying and type(plot.Destroying.Connect) == "function" then
            BindConn(plot.Destroying, function()
                if Runtime.Cache.PlotSavePlot == plot then
                    Runtime.Cache.PlotSavePlot = nil
                    table.clear(Runtime.Cache.PlotSaveEntries)
                    table.clear(Runtime.Cache.PlotSaveConnsBound)
                    Runtime.Cache.PedInfoCache = nil
                    Runtime.Cache.PedInfoVer = -1
                end
            end)
        end
    end

    local entries = Runtime.Cache.PlotSaveEntries
    local entry = entries[key]
    if not entry then
        entry = { val = nil, hasVal = false, at = 0, dirty = true, ver = 0 }
        entries[key] = entry
    end

    if not Runtime.Cache.PlotSaveConnsBound[key] and type(plot.SaveChanged) == "function" then
        Runtime.Cache.PlotSaveConnsBound[key] = true
        local okSig, sig = pcall(plot.SaveChanged, plot, key)
        if okSig and sig and type(sig.Connect) == "function" then
            BindConn(sig, function()
                if Runtime.Cache.PlotSavePlot ~= plot then
                    return
                end
                entry.dirty = true
                entry.at = 0
                entry.ver = (entry.ver or 0) + 1
                if key == VAR.Pedestals then
                    Runtime.Cache.PedInfoCache = nil
                elseif key == VAR.Buttons then
                    table.clear(Runtime.Cache.TargetEggCache)
                elseif key == VAR.Tutorial then
                    Runtime.Cache.TutorialDonePlot = nil
                end
            end)
        end
    end

    local now = os.clock()
    if not forceRefresh and entry.hasVal and not entry.dirty and (now - entry.at) < 1.5 then
        return entry.val, entry.ver
    end

    local okSave, res = pcall(plot.Save, plot, key)
    if okSave then
        entry.val = res
        entry.hasVal = true
        entry.at = now
        entry.dirty = false
        entry.ver = (entry.ver or 0) + 1
    end
    return entry.val, entry.ver
end

function Runtime.Helpers.HasCraftMachineUnlocked(machineName, plot, buttons)
    if Config.CraftRequireButtonComplete == false then
        return true
    end
    local btnState = buttons or (plot and Runtime.Helpers.GetPlotSave(plot, VAR.Buttons))
    if not btnState or not Modules.PumpkinButtonsUtil or not Modules.PumpkinButtonsUtil.Owned then
        return false
    end
    return Modules.PumpkinButtonsUtil.Owned(btnState, machineName) == true
end

local function GetFlag(keyName, fallback)
    local FFlags = Modules.FFlags
    if FFlags and FFlags.Keys and FFlags.Get then
        local k = FFlags.Keys[keyName]
        if k ~= nil then
            local ok, v = pcall(FFlags.Get, k)
            if ok and v ~= nil then
                return v
            end
        end
    end
    return fallback
end

local function IsInEventInstance()
    if Modules.InstancingCmds and Modules.InstancingCmds.IsInInstance then
        local ok, inside = pcall(Modules.InstancingCmds.IsInInstance, INSTANCE_ID)
        if ok and inside == true then
            return true
        end
    end
    if Modules.InstancingCmds and Modules.InstancingCmds.Get then
        local ok, info = pcall(Modules.InstancingCmds.Get)
        if ok and type(info) == "table" and info.instanceID == INSTANCE_ID then
            return true
        end
    end
    return LocalPlayer:GetAttribute("InstanceId") == INSTANCE_ID
end
Runtime.Helpers.IsInEventInstance = IsInEventInstance

local function GetMyPlot()
    if not Modules.ClientPlot or not Modules.ClientPlot.GetByPlayer then
        return nil
    end
    local ok, plot = pcall(Modules.ClientPlot.GetByPlayer, LocalPlayer)
    if ok and plot and not plot:IsDestroyed() then
        local dir = plot:GetDirectory()
        local dirId = type(dir) == "table" and (dir._id or dir.SaveId) or dir
        local targetDir = (PT and PT.PLOT_DIR) or INSTANCE_ID
        if dirId == targetDir or dirId == INSTANCE_ID then
            return plot
        end
    end
    return nil
end

local function GetIslandBox(plot)
    if not plot then
        return nil
    end
    local now = os.clock()
    if Runtime.Cache.IslandBox and (now - Runtime.Cache.IslandBoxAt < 2.0) then
        return Runtime.Cache.IslandBox
    end
    local model = plot:GetModel()
    if not model then
        return nil
    end
    local cf, size = model:GetBoundingBox()
    Runtime.Cache.IslandBox = { cf = cf, size = size, model = model }
    Runtime.Cache.IslandBoxAt = now
    return Runtime.Cache.IslandBox
end

local function IsOnMyIsland(model, islandBox)
    if not model or not model.Parent then
        return false
    end
    if model:GetAttribute("OwnerUsername") == LocalPlayer.Name then
        return true
    end
    if islandBox and PT and PT.OnIsland then
        return PT.OnIsland(islandBox.cf, islandBox.size, model:GetPivot().Position)
    end
    return false
end

function Runtime.Helpers.IsPlotPart2Active(plot)
    local flagOn = GetFlag("PumpkinTycoon_Part2", false) == true
    if not flagOn and PT_Cmds and type(PT_Cmds.Part2) == "function" then
        local ok, res = pcall(PT_Cmds.Part2)
        flagOn = ok and res == true
    end
    if not flagOn then
        return false
    end
    if plot and type(plot.GetModel) == "function" then
        local okM, model = pcall(plot.GetModel, plot)
        if okM and model then
            local builtAttr = (PT and PT.PART2_BUILT) or "Part2Built"
            return model:GetAttribute(builtAttr) == true
        end
    end
    return true
end

local function GetZoneCount(plot)
    if Runtime.Helpers.IsPlotPart2Active(plot) then
        return #(PT and PT.ZONES or {})
    end
    return (PT and PT.PART1_ZONES) or 5
end

local function GetProgressState(plot, forceRefresh)
    local buttons = plot and Runtime.Helpers.GetPlotSave(plot, VAR.Buttons, forceRefresh) or nil
    local isPart2 = Runtime.Helpers.IsPlotPart2Active(plot)
    local p1Done, p1Total = 0, 0
    local p2Done, p2Total = 0, 0
    local done, total = 0, 0
    local btnUtil = Modules.PumpkinButtonsUtil
    if btnUtil then
        if btnUtil.Progress then
            p1Done, p1Total = btnUtil.Progress(buttons, 1)
            if isPart2 then
                p2Done, p2Total = btnUtil.Progress(buttons, 2)
            end
        end
        if isPart2 and btnUtil.CompleteProgress then
            done, total = btnUtil.CompleteProgress(buttons, true)
        elseif isPart2 then
            done = p1Done + p2Done
            total = p1Total + p2Total
        else
            done, total = p1Done, p1Total
        end
    end

    local part1Complete = (p1Total > 0 and p1Done >= p1Total)
    local part2Complete = isPart2 and (p2Total > 0 and p2Done >= p2Total) or false
    local tycoonComplete = (total > 0 and done >= total)
    local claimedComplete = (btnUtil and btnUtil.Completed and btnUtil.Completed(buttons)) == true
    local claimedComplete2 = (btnUtil and btnUtil.Completed2 and btnUtil.Completed2(buttons)) == true
    local rawRebirths = plot and Runtime.Helpers.GetPlotSave(plot, VAR.Rebirths, forceRefresh) or 0
    local rebirths = math.max(0, math.floor(tonumber(rawRebirths) or 0))

    Runtime.Cache.Buttons = buttons
    Runtime.Cache.ButtonsAt = os.clock()
    Runtime.Stats.ButtonsDone = done
    Runtime.Stats.ButtonsTotal = total
    Runtime.Stats.Part1Complete = part1Complete
    Runtime.Stats.Part2Complete = part2Complete
    Runtime.Stats.TycoonComplete = tycoonComplete
    Runtime.Stats.CompletedClaimed = claimedComplete
    Runtime.Stats.Completed2Claimed = claimedComplete2
    Runtime.Stats.Rebirths = rebirths
    Runtime.Stats.Coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
    Runtime.Stats.Tokens = GetCurrency((PT and PT.TOKENS) or "PumpkinTokens")
    Runtime.Stats.IslandLuck = tonumber(LocalPlayer:GetAttribute("PumpkinTycoonIslandLuck")) or 0

    return buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths
end

-- ============================================================================
-- 5. JOIN & TUTORIAL
-- ============================================================================
local function EnsureInPumpkinTycoon()
    if IsInEventInstance() then
        local plot = GetMyPlot()
        if plot then
            return plot
        end
        Runtime.Stats.Phase = "Waiting Plot"
        local waitDeadline = os.clock() + 5
        while IsRunning() and IsInEventInstance() and os.clock() < waitDeadline do
            plot = GetMyPlot()
            if plot then
                Log("INFO", "Bound %s plot ID: %s", INSTANCE_ID, tostring(plot:GetId()))
                return plot
            end
            task.wait(0.15)
        end
        return nil
    end
    if not Config.AutoJoin then
        return nil
    end
    if os.clock() - (Runtime.Cache.LastJoinAttemptAt or 0) < 3.0 then
        return nil
    end
    Runtime.Cache.LastJoinAttemptAt = os.clock()

    Runtime.Stats.Phase = "Entering PumpkinTycoon"
    Log("INFO", "Joining %s instance...", INSTANCE_ID)

    if Modules.InstancingCmds and Modules.InstancingCmds.Enter then
        pcall(Modules.InstancingCmds.Enter, INSTANCE_ID)
    end
    if not IsInEventInstance() and Modules.Network and Modules.Network.Invoke then
        pcall(Modules.Network.Invoke, "Instancing_PlayerEnterInstance", INSTANCE_ID)
    end

    local deadline = os.clock() + 8
    while IsRunning() and os.clock() < deadline do
        local plot = GetMyPlot()
        if IsInEventInstance() and plot then
            Log("INFO", "Entered %s plot ID: %s", INSTANCE_ID, tostring(plot:GetId()))
            return plot
        end
        task.wait(0.2)
    end
    return nil
end

local function StepTutorial(plot)
    if not Config.AutoTutorial or not plot then
        return
    end
    if Runtime.Cache.TutorialDonePlot == plot then
        return
    end
    if Runtime.Helpers.GetPlotSave(plot, VAR.Tutorial) == true then
        Runtime.Cache.TutorialDonePlot = plot
        return
    end
    local now = os.clock()
    if now - (Runtime.Cache.LastTutorialInvokeAt or 0) < 5 then
        return
    end
    Runtime.Cache.LastTutorialInvokeAt = now
    local ok = pcall(plot.Invoke, plot, NET.TutorialDone)
    if ok then
        Runtime.Helpers.InvalidatePlotSave(plot, VAR.Tutorial)
        Log("DEBUG", "Completed island tutorial check.")
    end
end

-- ============================================================================
-- 6. PEDESTAL POLICY, LOCK, STOCK & MERCHANT
-- ============================================================================
function Runtime.Helpers.GetRungBaseCps(rung)
    local r = math.clamp(math.floor(tonumber(rung) or 1), 1, 8)
    local earn = Modules.PumpkinEarnUtil
    if earn and type(earn.Config) == "function" then
        local ok, cfg = pcall(earn.Config)
        if ok and type(cfg) == "table" and type(cfg.Cps) == "table" and type(cfg.Cps[r]) == "number" then
            return cfg.Cps[r]
        end
    end
    local fb = { 0.02, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 6 }
    return fb[r] or 0.02
end

function Runtime.Helpers.ComputePedestalEarnScore(standing)
    if type(standing) ~= "table" then
        return 0
    end
    local r = math.clamp(math.floor(tonumber(standing.R) or 1), 1, 8)
    local earn = Modules.PumpkinEarnUtil
    if earn and type(earn.Config) == "function" and type(earn.VariantMult) == "function" then
        local okC, cfg = pcall(earn.Config)
        if okC and type(cfg) == "table" and type(cfg.Cps) == "table" then
            local base = tonumber(cfg.Cps[r]) or Runtime.Helpers.GetRungBaseCps(r)
            local okV, vm = pcall(earn.VariantMult, cfg, standing)
            if okV and type(vm) == "number" and vm > 0 then
                return base * vm
            end
        end
    end
    local base = Runtime.Helpers.GetRungBaseCps(r)
    local vm = (standing.Rb and 5 or (standing.Gold and 2 or 1)) * (standing.Sh and 3 or 1)
    return base * vm
end

local function AnalyzePedestals(plot)
    local raw, ver = Runtime.Helpers.GetPlotSave(plot, VAR.Pedestals)
    if Runtime.Cache.PedInfoCache and Runtime.Cache.PedInfoVer == ver and Runtime.Cache.PlotSavePlot == plot then
        return Runtime.Cache.PedInfoCache
    end

    local maxPed = (PT and PT.MAX_PEDESTALS) or 8
    local unlockedIndices = {}
    local emptyIndices = {}
    local occupied = {}
    local lockedList = {}
    local byIndex = {}

    if type(raw) == "table" then
        for i = 1, maxPed do
            local entry = raw[i]
            if type(entry) == "table" and entry.Unlocked == true then
                table.insert(unlockedIndices, i)
                if type(entry.Standing) ~= "table" then
                    table.insert(emptyIndices, i)
                else
                    local rung = tonumber(entry.Standing.R) or 1
                    local isLocked = entry.Locked == true
                    local earnScore = Runtime.Helpers.ComputePedestalEarnScore(entry.Standing)
                    local item = {
                        index = i,
                        rung = rung,
                        locked = isLocked,
                        earnScore = earnScore,
                        standing = entry.Standing,
                    }
                    byIndex[i] = item
                    table.insert(occupied, item)
                    if isLocked then
                        table.insert(lockedList, item)
                    end
                end
            end
        end
    end

    table.sort(lockedList, function(a, b)
        if a.earnScore ~= b.earnScore then
            return a.earnScore < b.earnScore
        end
        if a.rung ~= b.rung then
            return a.rung < b.rung
        end
        return a.index < b.index
    end)

    local info = {
        raw = raw,
        unlockedCount = #unlockedIndices,
        emptyIndices = emptyIndices,
        occupied = occupied,
        lockedList = lockedList,
        byIndex = byIndex,
    }
    Runtime.Cache.PedInfoCache = info
    Runtime.Cache.PedInfoVer = ver
    return info
end

local function ComputeMinFarmPedestals(unlockedCount, part2AutoKeep)
    if unlockedCount <= 1 then
        return unlockedCount
    end
    if type(Config.MinFarmPedestals) == "number" then
        return math.clamp(math.floor(Config.MinFarmPedestals), 1, math.max(1, unlockedCount - 1))
    end
    if part2AutoKeep then
        return math.clamp(math.floor(tonumber(Config.Part2MinFarmPedestals) or 1), 1, math.max(1, unlockedCount - 1))
    end
    return (unlockedCount >= 5) and 2 or 1
end

local function GetServerMaxBelow()
    if PT_AutoBreak and PT_AutoBreak.MaxBelow then
        local ok, m = pcall(PT_AutoBreak.MaxBelow)
        if ok and type(m) == "number" then
            return m
        end
    end
    local f = tonumber(GetFlag("PumpkinTycoon_AutoBreakFreeBelow", 8))
    return f or 8
end

local function GetKeepLockSettings(maxAllowed, unlockedCount, plot, buttons)
    local limit = type(maxAllowed) == "number" and math.max(0, math.floor(maxAllowed)) or 8
    local keepDesired = math.clamp(math.floor(tonumber(Config.KeepRung) or 0), 0, limit)
    if keepDesired == 1 then
        keepDesired = 0
    end

    local part2AutoKeep = false
    if keepDesired == 0 and Config.AutoKeepPart2Pedestals ~= false then
        local p = plot or GetMyPlot()
        local btns = buttons or Runtime.Cache.Buttons
        local z6Owned = Modules.PumpkinButtonsUtil and btns and Modules.PumpkinButtonsUtil.Owned(btns, "Zone6_Zone")
        if z6Owned and p and Runtime.Helpers.IsPlotPart2Active(p) then
            keepDesired = math.clamp(math.floor(tonumber(Config.Part2KeepMinRung) or 4), 2, limit)
            part2AutoKeep = true
        end
    end

    local lockMin = 0
    if keepDesired >= 2 then
        local configuredLock = math.floor(tonumber(Config.LockMinRung) or 0)
        if configuredLock == 1 then
            configuredLock = 0
        end
        lockMin = (configuredLock >= 2) and configuredLock or keepDesired
    end

    local maxKeepSlots = 0
    if keepDesired >= 2 and lockMin >= 2 and type(unlockedCount) == "number" and unlockedCount > 0 then
        local minFarm = ComputeMinFarmPedestals(unlockedCount, part2AutoKeep)
        maxKeepSlots = math.max(0, unlockedCount - minFarm)
    end

    return keepDesired, lockMin, maxKeepSlots, part2AutoKeep
end

local function IsProtectedForLockQueue(pedInfo, maxKeepSlots, pedIdx, rung, cachedLockMin)
    local lockMin = cachedLockMin
    if lockMin == nil then
        _, lockMin = GetKeepLockSettings(nil, pedInfo and pedInfo.unlockedCount)
    end
    if lockMin < 2 or maxKeepSlots <= 0 then
        return false
    end
    local minScore = Runtime.Helpers.GetRungBaseCps(lockMin)
    local occ = pedInfo and pedInfo.byIndex and pedInfo.byIndex[pedIdx]
    local candScore = (occ and occ.earnScore) or Runtime.Helpers.ComputePedestalEarnScore({ R = rung })
    if candScore + 1e-9 < minScore then
        return false
    end
    -- Skip temporarily only if Loop A can lock it outright or swap out a lower-earning locked pedestal
    if #pedInfo.lockedList < maxKeepSlots then
        return true
    end
    if Config.AutoLockUpgradeSwap and #pedInfo.lockedList > 0 and candScore > (pedInfo.lockedList[1].earnScore + 1e-6) then
        return true
    end
    return false
end

local function StepKeepLockAndStock(plot, buttons, tycoonComplete)
    if not plot or not Modules.MerchantTypes then
        return
    end
    local now = os.clock()
    if now - (Runtime.Cache.LastKeepLockStepAt or 0) < 0.5 then
        return
    end
    Runtime.Cache.LastKeepLockStepAt = now

    local pedInfo = AnalyzePedestals(plot)
    if pedInfo.unlockedCount == 0 then
        Runtime.Stats.LockedPedestals = 0
        Runtime.Stats.MaxKeepSlots = 0
        return
    end

    local maxAllowed = GetServerMaxBelow()
    local keepDesired, lockMin, maxKeepSlots, part2AutoKeep = GetKeepLockSettings(maxAllowed, pedInfo.unlockedCount, plot, buttons)
    local minFarm = ComputeMinFarmPedestals(pedInfo.unlockedCount, part2AutoKeep)
    local lockedList = table.clone(pedInfo.lockedList)

    -- 1. Enforce maxKeepSlots invariant (unlocks all pedestals when KeepRung=0 in Part 1, or trims excess locked slots)
    while #lockedList > maxKeepSlots do
        local weakest = table.remove(lockedList, 1)
        pcall(plot.Invoke, plot, NET.SetLock, weakest.index, false)
        Runtime.Helpers.InvalidatePlotSave(plot, VAR.Pedestals)
        task.wait(0.04)
    end

    -- 2. Lock highest-earning pedestals (EarnRate = Cps[Rung] * VariantMult) and swap weaker ones upward
    if lockMin >= 2 and maxKeepSlots > 0 then
        local minScore = Runtime.Helpers.GetRungBaseCps(lockMin)
        local candidates = {}
        for _, occ in ipairs(pedInfo.occupied) do
            if not occ.locked and (occ.earnScore or 0) + 1e-9 >= minScore then
                table.insert(candidates, occ)
            end
        end
        table.sort(candidates, function(a, b)
            if a.earnScore ~= b.earnScore then
                return a.earnScore > b.earnScore
            end
            return a.rung > b.rung
        end)

        for _, cand in ipairs(candidates) do
            if #lockedList < maxKeepSlots then
                local ok, res = pcall(plot.Invoke, plot, NET.SetLock, cand.index, true)
                if ok and res ~= false then
                    Runtime.Helpers.InvalidatePlotSave(plot, VAR.Pedestals)
                    table.insert(lockedList, { index = cand.index, rung = cand.rung, earnScore = cand.earnScore, locked = true })
                    table.sort(lockedList, function(a, b)
                        if a.earnScore ~= b.earnScore then
                            return a.earnScore < b.earnScore
                        end
                        return a.rung < b.rung
                    end)
                    Log("INFO", "Locked Pedestal #%d (R%d, earn=%.2fx) [%d/%d]", cand.index, cand.rung, cand.earnScore, #lockedList, maxKeepSlots)
                end
                task.wait(0.04)
            elseif Config.AutoLockUpgradeSwap and #lockedList > 0 and cand.earnScore > (lockedList[1].earnScore + 1e-6) then
                local weakest = table.remove(lockedList, 1)
                local uOk = pcall(plot.Invoke, plot, NET.SetLock, weakest.index, false)
                if uOk then
                    Runtime.Helpers.InvalidatePlotSave(plot, VAR.Pedestals)
                    task.wait(0.04)
                    local lOk, lRes = pcall(plot.Invoke, plot, NET.SetLock, cand.index, true)
                    if lOk and lRes ~= false then
                        Runtime.Helpers.InvalidatePlotSave(plot, VAR.Pedestals)
                        table.insert(lockedList, { index = cand.index, rung = cand.rung, earnScore = cand.earnScore, locked = true })
                        table.sort(lockedList, function(a, b)
                            if a.earnScore ~= b.earnScore then
                                return a.earnScore < b.earnScore
                            end
                            return a.rung < b.rung
                        end)
                        Log("INFO", "Swapped Pedestal #%d (%.2fx) -> #%d (R%d, earn=%.2fx)", weakest.index, weakest.earnScore or 0, cand.index, cand.rung, cand.earnScore)
                    end
                end
                task.wait(0.04)
            end
        end
    end

    Runtime.Stats.LockedPedestals = #lockedList
    Runtime.Stats.MaxKeepSlots = maxKeepSlots

    -- 3. AutoPlace Stock setting + proactive allocation onto empty pedestals (highest band first)
    local merchantOwned = Modules.PumpkinButtonsUtil and Modules.PumpkinButtonsUtil.Owned(buttons, Modules.MerchantTypes.BUTTON)
    if merchantOwned and Config.AutoPlaceStock then
        local currentAutoPlace = Runtime.Helpers.GetPlotSave(plot, "StockAutoPlace")
        if currentAutoPlace == false and Runtime.Cache.LastAutoPlace ~= true then
            Runtime.Cache.LastAutoPlace = true
            pcall(plot.Invoke, plot, NET.SetAutoPlace, true)
            Runtime.Helpers.InvalidatePlotSave(plot, "StockAutoPlace")
        end

        local stockList = Modules.MerchantTypes.CleanStock(Runtime.Helpers.GetPlotSave(plot, VAR.Stock))
        if #stockList > 0 and #pedInfo.emptyIndices > 0 then
            local counts = {}
            for _, bandKey in ipairs(stockList) do
                counts[bandKey] = (counts[bandKey] or 0) + 1
            end
            local bands = Modules.MerchantTypes.BANDS or {}
            local emptyCursor = 1
            for idx = #bands, 1, -1 do
                local bandKey = bands[idx]
                while (counts[bandKey] or 0) > 0 and emptyCursor <= #pedInfo.emptyIndices do
                    local emptyPedIdx = pedInfo.emptyIndices[emptyCursor]
                    local ok, res = pcall(plot.Invoke, plot, NET.PlaceStock, emptyPedIdx, bandKey)
                    emptyCursor = emptyCursor + 1
                    counts[bandKey] = counts[bandKey] - 1
                    if ok and res ~= false then
                        Runtime.Helpers.InvalidatePlotSave(plot, VAR.Stock)
                        Runtime.Helpers.InvalidatePlotSave(plot, VAR.Pedestals)
                    else
                        break
                    end
                    task.wait(0.04)
                end
            end
        end
    end

    -- 4. Adaptive Keep Rule (QW_Policy): protect target KeepRung until Keep slots saturate, then Secret-guard
    if os.clock() - (Runtime.Cache.LastPolicyInvokeAt or 0) >= 0.6 then
        local targetPolicy = keepDesired
        if keepDesired <= 0 or pedInfo.unlockedCount <= minFarm then
            targetPolicy = 0
        elseif #lockedList >= maxKeepSlots then
            -- Lock slots full; only pause Secret spawns briefly until Lock loop swaps them in
            targetPolicy = (maxAllowed >= 8) and 8 or 0
        end

        local rawAuto = Runtime.Helpers.GetPlotSave(plot, VAR.AutoBreak)
        local currentPolicy = (type(rawAuto) == "table" and tonumber(rawAuto.Below))
            or tonumber(rawAuto)
            or 0
        if currentPolicy ~= targetPolicy then
            Runtime.Cache.LastPolicyInvokeAt = os.clock()
            local ok, res = pcall(plot.Invoke, plot, NET.SetAutoBreak, targetPolicy)
            if ok and res ~= false then
                Runtime.Helpers.InvalidatePlotSave(plot, VAR.AutoBreak)
                Log("DEBUG", "Updated Keep policy (QW_Policy): %d -> %d (locked %d/%d)", currentPolicy, targetPolicy, #lockedList, maxKeepSlots)
            end
        end
    end

    -- 5. Merchant Buying & Server AutoMerchant control
    if not merchantOwned then
        return
    end

    -- Keep server HM_Sustain OFF if configured so it doesn't fill stock slots with low tiers
    local autoVar = Modules.MerchantTypes.AUTO_VAR
    local autoOn = Runtime.Helpers.GetPlotSave(plot, autoVar) == true
    if (Config.KeepServerAutoMerchantOff or (Config.RushButtonsFirst and not tycoonComplete)) and autoOn then
        pcall(plot.Invoke, plot, NET.SetAutoMerchant, false)
        Runtime.Helpers.InvalidatePlotSave(plot, autoVar)
    end

    if not Config.AutoBuyMerchant or (Config.MerchantRequireButtonsComplete and not tycoonComplete) or Runtime.Stats.FightingTurkeyBoss then
        return
    end

    local rushMode = (Config.RushButtonsFirst == true and not tycoonComplete)
    if rushMode and Config.MerchantRushRequireZone6 ~= false then
        if not (Modules.PumpkinButtonsUtil and Modules.PumpkinButtonsUtil.Owned(buttons, "Zone6_Zone")) then
            return
        end
    end

    local coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
    Runtime.Stats.Coins = coins
    local activateCoins = tonumber(Config.MerchantActivateCoins) or 0
    local spareCoins = tonumber(Config.MerchantMinSpareCoins) or 0
    local rushShare = math.clamp(tonumber(Config.MerchantRushMaxCoinShare) or 0.05, 0, 1)
    if not rushMode and coins < activateCoins then
        return
    end
    if rushMode and rushShare <= 0 then
        return
    end

    local merchantClean = Modules.MerchantTypes.Clean(Runtime.Helpers.GetPlotSave(plot, VAR.Merchant))
    if not merchantClean or type(merchantClean.Items) ~= "table" then
        return
    end

    if os.clock() - (Runtime.Cache.LastMerchantFailAt or 0) < 15 then
        return
    end

    local stockCount = #Modules.MerchantTypes.CleanStock(Runtime.Helpers.GetPlotSave(plot, VAR.Stock))
    local maxSlots = LocalPlayer:GetAttribute(Modules.MerchantTypes.ATTR_SLOTS) or Modules.MerchantTypes.BaseSlots()
    local bandConfigs = Modules.MerchantTypes.Config()

    local function CanBuyBand(price, curCoins)
        if type(price) ~= "number" or price <= 0 then
            return false
        end
        if rushMode then
            local spendable = math.max(0, curCoins - (Runtime.Cache.ReserveEarlyEggCost or 0))
            return spendable >= price and price <= (curCoins * rushShare)
        end
        return curCoins >= activateCoins and (curCoins - price) >= spareCoins
    end

    local hasCandidate = false
    for _, bandKey in ipairs(Config.MerchantBandOrder or {}) do
        if Config.AllowedMerchantBands[bandKey] == true then
            local avail = merchantClean.Items[bandKey] or 0
            local bandCfg = bandConfigs and bandConfigs[bandKey]
            local price = bandCfg and bandCfg.Price
            if avail > 0 and stockCount < maxSlots and CanBuyBand(price, coins) then
                hasCandidate = true
                break
            end
        end
    end
    if not hasCandidate then
        return
    end

    WithMachinePad(plot, Modules.MerchantTypes.MACHINE, Modules.MerchantTypes.Range, function()
        for _, bandKey in ipairs(Config.MerchantBandOrder or {}) do
            if Config.AllowedMerchantBands[bandKey] == true then
                local avail = merchantClean.Items[bandKey] or 0
                local bandCfg = bandConfigs and bandConfigs[bandKey]
                local price = bandCfg and bandCfg.Price
                while IsRunning() and avail > 0 and stockCount < maxSlots and CanBuyBand(price, coins) do
                    local ok, res, reason = pcall(plot.Invoke, plot, NET.BuyBand, bandKey)
                    if not ok or res ~= true then
                        Runtime.Cache.LastMerchantFailAt = os.clock()
                        Log("DEBUG", "Merchant buy failed [%s]: %s", tostring(bandKey), tostring(reason or res))
                        return
                    end
                    Runtime.Cache.LastMerchantFailAt = 0
                    Runtime.Helpers.InvalidatePlotSave(plot, VAR.Merchant)
                    Runtime.Helpers.InvalidatePlotSave(plot, VAR.Stock)
                    Runtime.Helpers.RecordCoinsSpent(price)
                    avail = avail - 1
                    stockCount = stockCount + 1
                    coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
                    Runtime.Stats.Coins = coins
                    Log("INFO", "Bought Merchant %s pumpkin for %s Coins", bandKey, tostring(price))
                    task.wait(0.05)
                end
            end
        end
    end)
end

-- ============================================================================
-- 7. BREAKABLES FARM ENGINE (ULTRA-FAST TAP + PET TARGETING + ORBS/LOOTBAGS)
-- ============================================================================
local activeFarmTarget = nil -- { uid = string, model = Model, pos = Vector3, isBonus = bool, rung = number }

local function BelongsToPlot(model, attrs, islandBox, plotId, plotSuffix)
    if type(attrs) == "table" and attrs.Plot ~= nil then
        return attrs.Plot == plotId
    end
    local owner = model:GetAttribute("OwnerUsername")
    if owner ~= nil then
        return owner == LocalPlayer.Name
    end
    local areaId = model:GetAttribute("AreaID")
    if type(areaId) == "string" and plotSuffix then
        if string.sub(areaId, -#plotSuffix) == plotSuffix then
            return true
        end
        if string.find(areaId, "_Zone_", 1, true) then
            return false
        end
    end
    return IsOnMyIsland(model, islandBox)
end

local function ResolveBreakableZoneIndex(data, model, attrs)
    local zn = tonumber(data and data.zoneNumber) or tonumber(attrs and attrs.ZoneNumber)
    if not zn and model then
        zn = tonumber(model:GetAttribute("ZoneNumber"))
    end
    if zn and zn >= 1 then
        return zn
    end
    local areaId = (data and data.areaID) or (attrs and attrs.AreaID) or (model and model:GetAttribute("AreaID"))
    if type(areaId) == "string" and PT and type(PT.ZONES) == "table" then
        for i, z in ipairs(PT.ZONES) do
            if z and z.Section and string.find(areaId, z.Section, 1, true) then
                return i
            end
        end
    end
    return 1
end

local function CollectMyBreakables(plot, pedInfo)
    Runtime.Cache.TargetsUseB = not Runtime.Cache.TargetsUseB
    local targets = Runtime.Cache.TargetsUseB and Runtime.Cache.TargetsBufB or Runtime.Cache.TargetsBufA
    local entryPool = Runtime.Cache.TargetsUseB and Runtime.Cache.EntryPoolB or Runtime.Cache.EntryPoolA
    table.clear(targets)

    if not plot or not Modules.BreakableFrontend or not Modules.BreakableFrontend.AllByInstanceAndClass then
        return targets
    end

    local allByClass = Runtime.Cache.AllByClassScratch
    table.clear(allByClass)
    for _, cls in ipairs({ "Chest", "Normal" }) do
        local ok, res = pcall(Modules.BreakableFrontend.AllByInstanceAndClass, cls)
        if ok and type(res) == "table" then
            for uid, data in pairs(res) do
                allByClass[uid] = data
            end
        end
    end

    local islandBox = GetIslandBox(plot)
    local plotId = plot:GetId()
    local plotSuffix = plotId and ("_" .. tostring(plotId)) or nil
    local buttons = Runtime.Cache.Buttons
    local _, cachedLockMin, maxKeepSlots = GetKeepLockSettings(nil, pedInfo.unlockedCount, plot, buttons)
    local z6Owned = Modules.PumpkinButtonsUtil and buttons and Modules.PumpkinButtonsUtil.Owned(buttons, "Zone6_Zone")
    local lowPedSweepInterval = math.max(0, tonumber(Config.PedestalLowRungSweepIntervalSec) or 20)
    local nowClock = os.clock()
    local allowFarLowPed = (not z6Owned)
        or (lowPedSweepInterval <= 0)
        or ((nowClock - (Runtime.Cache.LastLowRungPedSweepAt or 0)) >= lowPedSweepInterval)
    local lockedPedestals = Runtime.Cache.LockedPedScratch
    table.clear(lockedPedestals)
    for _, l in ipairs(pedInfo.lockedList) do
        lockedPedestals[l.index] = true
    end

    local _, hrp = GetCharacter()
    local playerPos = hrp and hrp.Position
    local emergencyFallback = Runtime.Cache.EmergencyScratch
    table.clear(emergencyFallback)
    local poolIdx = 0

    for uid, data in pairs(allByClass) do
        local model = data and data.model
        local attrs = (data and data.clientAttributes)
        if model and model.Parent and BelongsToPlot(model, attrs, islandBox, plotId, plotSuffix) then
            local isBonus = type(attrs) == "table" and ((attrs.OrchardChest ~= nil) or (attrs.HayPile == true)) or false
            local pedIdx = type(attrs) == "table" and attrs.PumpkinPedestal or nil
            local rung = type(attrs) == "table" and (tonumber(attrs.PumpkinRung) or 1) or 1

            local valid = false
            local eligibleFallback = false
            if isBonus and Config.FarmOrchardAndHay then
                valid = true
            elseif type(pedIdx) == "number" then
                if not lockedPedestals[pedIdx] then
                    eligibleFallback = true
                    if not IsProtectedForLockQueue(pedInfo, maxKeepSlots, pedIdx, rung, cachedLockMin) then
                        valid = true
                    end
                end
            else
                -- Normal zone breakables (coins, crates, presents, safes) on our island/zone
                valid = true
            end

            if valid or eligibleFallback then
                if valid and model:GetAttribute("ManualDamage") ~= nil then
                    pcall(model.SetAttribute, model, "ManualDamage", nil)
                end
                local pos = model:GetPivot().Position
                local dist = playerPos and HorizontalDist(playerPos, pos) or 0
                local zoneNum = (not isBonus and type(pedIdx) ~= "number") and ResolveBreakableZoneIndex(data, model, attrs) or 0
                local score
                if isBonus then
                    score = 1000000 - (dist * 0.25)
                elseif type(pedIdx) == "number" then
                    -- In Part 2 Zone 6+, avoid yanking all pets 700 studs back to Zone 1 every 2s for R1-R2 pedestals (1-3 Tokens)
                    if z6Owned and rung <= 2 and dist > 180 and not allowFarLowPed then
                        score = 1000 + (rung * 500) - (dist * 0.25)
                    else
                        score = 50000 + (rung * 500) - (dist * 0.25)
                    end
                else
                    -- Highest unlocked Zone dominates distance penalty across the whole island
                    score = 5000 + (zoneNum * 2000) - (dist * 0.25)
                end
                poolIdx = poolIdx + 1
                local entry = entryPool[poolIdx]
                if not entry then
                    entry = {}
                    entryPool[poolIdx] = entry
                end
                entry.uid = tostring(uid)
                entry.model = model
                entry.pos = pos
                entry.isBonus = isBonus
                entry.isPedestal = (type(pedIdx) == "number")
                entry.zone = zoneNum
                entry.rung = rung
                entry.dist = dist
                entry.score = score

                if valid then
                    table.insert(targets, entry)
                else
                    table.insert(emergencyFallback, entry)
                end
            end
        end
    end

    if #targets == 0 and #emergencyFallback > 0 then
        -- Deadlock safety: break lowest-rung unlocked pedestal if every unlocked slot paused simultaneously
        table.sort(emergencyFallback, function(a, b)
            if a.rung ~= b.rung then
                return a.rung < b.rung
            end
            return a.dist < b.dist
        end)
        targets[1] = emergencyFallback[1]
        return targets
    end

    table.sort(targets, function(a, b)
        return a.score > b.score
    end)

    return targets
end

local function HoldPetOnModel(pet, targetModel)
    if not pet or not targetModel or not targetModel.Parent then
        return
    end
    local okT, tgtType = pcall(pet.GetTargetType, pet)
    local okG, curTgt = pcall(pet.GetTarget, pet)
    if not okT or not okG or tgtType ~= "Breakable" or curTgt ~= targetModel then
        pcall(pet.SetAnchored, pet, false)
        pcall(pet.SetTarget, pet, targetModel)
    end
    pet.AIHold = "PumpkinKaitun"
end

local function GetControllablePets()
    if not Config.AutoPetFocus or not Modules.PlayerPet or not Modules.PlayerPet.GetByPlayer then
        return nil
    end
    local ok, pets = pcall(Modules.PlayerPet.GetByPlayer, LocalPlayer)
    if not ok or type(pets) ~= "table" then
        return nil
    end
    local list = Runtime.Cache.ControllablePetsScratch
    if not list then
        list = {}
        Runtime.Cache.ControllablePetsScratch = list
    else
        table.clear(list)
    end
    for _, pet in pairs(pets) do
        if pet and (pet.AIHold == nil or pet.AIHold == "PumpkinAutoBreak" or pet.AIHold == "PumpkinKaitun") then
            table.insert(list, pet)
        end
    end
    return list
end

local function AssignPetsToModel(targetModel)
    if not targetModel or not targetModel.Parent then
        return
    end
    local pets = GetControllablePets()
    if not pets then
        return
    end
    for _, pet in ipairs(pets) do
        HoldPetOnModel(pet, targetModel)
    end
end

local function AssignPetsSpread(zonePool)
    if type(zonePool) ~= "table" or #zonePool == 0 then
        return
    end
    local pets = GetControllablePets()
    if not pets or #pets == 0 then
        return
    end

    local poolByModel = Runtime.Cache.PoolByModelScratch
    local claimedCount = Runtime.Cache.ClaimedCountScratch
    table.clear(poolByModel)
    table.clear(claimedCount)
    for _, entry in ipairs(zonePool) do
        if entry.model and entry.model.Parent then
            poolByModel[entry.model] = entry
            claimedCount[entry.model] = 0
        end
    end

    local needAssign = Runtime.Cache.NeedAssignScratch
    table.clear(needAssign)
    for _, pet in ipairs(pets) do
        local okT, tgtType = pcall(pet.GetTargetType, pet)
        local okG, curTgt = pcall(pet.GetTarget, pet)
        if okT and okG and tgtType == "Breakable" and curTgt and poolByModel[curTgt] and claimedCount[curTgt] < 1 then
            claimedCount[curTgt] = claimedCount[curTgt] + 1
            pet.AIHold = "PumpkinKaitun"
        else
            table.insert(needAssign, pet)
        end
    end

    for _, pet in ipairs(needAssign) do
        local bestEntry = nil
        local bestCount = math.huge
        for _, entry in ipairs(zonePool) do
            if entry.model and entry.model.Parent then
                local c = claimedCount[entry.model] or 0
                if c < bestCount then
                    bestCount = c
                    bestEntry = entry
                    if c == 0 then
                        break
                    end
                end
            end
        end
        if bestEntry then
            HoldPetOnModel(pet, bestEntry.model)
            claimedCount[bestEntry.model] = (claimedCount[bestEntry.model] or 0) + 1
        end
    end
end

local function GetTapReach()
    local now = os.clock()
    if Runtime.Cache.TapReachVal and (now - (Runtime.Cache.TapReachAt or 0)) < 3.0 then
        return Runtime.Cache.TapReachVal
    end
    local val = 18
    if PT_AutoBreak and PT_AutoBreak.TapReach then
        local ok, r = pcall(PT_AutoBreak.TapReach)
        if ok and type(r) == "number" and r > 0 then
            val = r
        end
    end
    Runtime.Cache.TapReachVal = val
    Runtime.Cache.TapReachAt = now
    return val
end

local function StepFarmTargeter(plot)
    if plot and Runtime.Helpers.StepTurkeyBossTarget and Runtime.Helpers.StepTurkeyBossTarget(plot) then
        return
    end
    if not Config.AutoFarm or not plot then
        activeFarmTarget = nil
        Runtime.Stats.ActiveTargetUid = nil
        Runtime.Stats.ActiveTargetDesc = "Idle"
        ReleaseHeldPets()
        return
    end

    local pedInfo = AnalyzePedestals(plot)
    local targets = CollectMyBreakables(plot, pedInfo)
    Runtime.Cache.TapTargets = targets
    if #targets == 0 then
        activeFarmTarget = nil
        Runtime.Stats.ActiveTargetUid = nil
        Runtime.Stats.ActiveTargetDesc = "Waiting spawn"
        return
    end

    local prevWasLowPed = activeFarmTarget ~= nil
        and activeFarmTarget.isPedestal == true
        and (activeFarmTarget.rung or 1) <= 2
    local prevUid = activeFarmTarget and activeFarmTarget.uid or nil
    local prevDead = activeFarmTarget ~= nil and (not activeFarmTarget.model or not activeFarmTarget.model.Parent)

    -- Sticky target hysteresis to avoid rapid flickering; break immediately for BonusChest, Pedestal, or a higher Zone
    local chosen = targets[1]
    if activeFarmTarget and activeFarmTarget.model and activeFarmTarget.model.Parent then
        for _, cand in ipairs(targets) do
            if cand.uid == activeFarmTarget.uid then
                local upgradeToPedestal = chosen.isPedestal and not cand.isPedestal
                local upgradeToHigherZone = (not cand.isPedestal) and (not chosen.isPedestal) and ((chosen.zone or 1) > (cand.zone or 1))
                if not chosen.isBonus and not upgradeToPedestal and not upgradeToHigherZone and chosen.rung < cand.rung + 2 then
                    chosen = cand
                end
                break
            end
        end
    end

    if prevWasLowPed and (prevDead or chosen.uid ~= prevUid) then
        Runtime.Cache.LastLowRungPedSweepAt = os.clock()
    end

    local targetCopy = Runtime.Cache.ActiveTargetCopy
    targetCopy.uid = chosen.uid
    targetCopy.model = chosen.model
    targetCopy.pos = chosen.pos
    targetCopy.isBonus = chosen.isBonus
    targetCopy.isPedestal = chosen.isPedestal
    targetCopy.isTurkeyBoss = false
    targetCopy.zone = chosen.zone
    targetCopy.rung = chosen.rung
    targetCopy.dist = chosen.dist
    targetCopy.score = chosen.score
    activeFarmTarget = targetCopy

    Runtime.Stats.ActiveTargetUid = chosen.uid
    Runtime.Stats.ActiveTargetDesc = chosen.isBonus and "BonusChest"
        or (chosen.isPedestal and ("Ped-Rung-" .. tostring(chosen.rung)) or ("Zone-" .. tostring(chosen.zone or 1)))

    -- Keep character inside both TapReach and Egg range when Hatching overlaps with breakables
    if Config.AutoTeleportToTarget and not IsMoveLocked() then
        local reach = GetTapReach()
        local moveRange = math.max(10, reach - 5)
        local hatchEggPos = Runtime.Stats.IsHatching and Runtime.Cache.ActiveHatchEggPos or nil
        if hatchEggPos then
            local safeEggRadius = math.clamp((tonumber(Config.HatchMoveMaxDist) or 30) - 8, 10, 22)
            local _, curHrp = GetCharacter()
            local dest = chosen.pos
            if HorizontalDist(dest, hatchEggPos) > safeEggRadius then
                local dx = dest.X - hatchEggPos.X
                local dz = dest.Z - hatchEggPos.Z
                local hMag = math.sqrt(dx * dx + dz * dz)
                if hMag > 1e-3 then
                    dest = Vector3.new(hatchEggPos.X + (dx / hMag) * safeEggRadius, dest.Y, hatchEggPos.Z + (dz / hMag) * safeEggRadius)
                else
                    dest = Vector3.new(hatchEggPos.X, dest.Y, hatchEggPos.Z)
                end
            end
            if not curHrp or HorizontalDist(curHrp.Position, hatchEggPos) > (safeEggRadius + 6) or HorizontalDist(curHrp.Position, dest) > moveRange then
                MoveNear(dest, 4)
            end
        elseif chosen.dist > moveRange then
            MoveNear(chosen.pos, moveRange)
        end
    end

    if not chosen.isBonus and not chosen.isPedestal and Config.AutoSpreadZoneBreakables ~= false then
        local topZone = chosen.zone or 1
        local zonePool = Runtime.Cache.ZonePoolScratch
        table.clear(zonePool)
        for _, cand in ipairs(targets) do
            if not cand.isBonus and not cand.isPedestal and (cand.zone or 1) == topZone then
                table.insert(zonePool, cand)
            end
        end
        if #zonePool > 0 then
            AssignPetsSpread(zonePool)
            return
        end
    end

    AssignPetsToModel(chosen.model)
end

local function PickInRangeTapTargetUid(hrpPos, baseReach)
    if activeFarmTarget and activeFarmTarget.model and activeFarmTarget.model.Parent then
        local m = activeFarmTarget.model
        local attrReach = tonumber(m:GetAttribute("AutoTapRadius"))
        local r = attrReach and math.max(baseReach, attrReach) or baseReach
        if activeFarmTarget.isTurkeyBoss and Runtime.Helpers.GetTurkeyReach then
            r = math.max(r, Runtime.Helpers.GetTurkeyReach())
        end
        if HorizontalDist(hrpPos, m:GetPivot().Position) <= r then
            return activeFarmTarget.uid
        end
    end
    local pool = Runtime.Cache.TapTargets
    if type(pool) == "table" then
        for _, entry in ipairs(pool) do
            local m = entry and entry.model
            if m and m.Parent then
                local attrReach = tonumber(m:GetAttribute("AutoTapRadius"))
                local r = attrReach and math.max(baseReach, attrReach) or baseReach
                if HorizontalDist(hrpPos, m:GetPivot().Position) <= r then
                    return entry.uid
                end
            end
        end
    end
    return nil
end

local function StepRapidTap()
    if not Config.AutoTap or (not activeFarmTarget and type(Runtime.Cache.TapTargets) ~= "table") then
        return
    end
    local _, hrp = GetCharacter()
    if not hrp then
        return
    end

    local targetUid = PickInRangeTapTargetUid(hrp.Position, GetTapReach())
    if not targetUid then
        return
    end

    if Config.TapSendAutoClickerSignal and Modules.Signal and Modules.Signal.Fire then
        pcall(Modules.Signal.Fire, "AutoClicker_Nearby", targetUid)
    end
    if Modules.Network and Modules.Network.UnreliableFire then
        pcall(Modules.Network.UnreliableFire, "Breakables_PlayerDealDamage", targetUid)
    end
end

local function FireOrbsCollect(batch)
    local orbRemote = Runtime.Cache.CachedOrbRemote
    if not orbRemote or not orbRemote.Parent then
        local netFolder = ReplicatedStorage:FindFirstChild("Network")
        orbRemote = netFolder and netFolder:FindFirstChild("Orbs: Collect")
        Runtime.Cache.CachedOrbRemote = orbRemote
    end
    if orbRemote and orbRemote:IsA("RemoteEvent") then
        pcall(orbRemote.FireServer, orbRemote, batch)
    elseif Modules.Network and Modules.Network.Fire then
        pcall(Modules.Network.Fire, "Orbs: Collect", table.clone(batch))
    end
end

function Runtime.Helpers.EnsureOrbsCreateHook()
    if Runtime.Cache.OrbsCreateConnBound then
        return
    end
    local net = Modules.Network
    if not net or type(net.Fired) ~= "function" then
        return
    end
    local okSig, sig = pcall(net.Fired, "Orbs: Create")
    if okSig and sig and type(sig.Connect) == "function" then
        Runtime.Cache.OrbsCreateConnBound = true
        BindConn(sig, function(data)
            if not IsRunning() or not Config.AutoCollectOrbs or type(data) ~= "table" then
                return
            end
            local batch = nil
            for _, orb in ipairs(data) do
                local numId = type(orb) == "table" and tonumber(orb.id) or nil
                if numId then
                    if not batch then
                        batch = {}
                    end
                    table.insert(batch, numId)
                    if #batch >= 50 then
                        FireOrbsCollect(batch)
                        batch = {}
                    end
                end
            end
            if batch and #batch > 0 then
                FireOrbsCollect(batch)
            end
        end)
    end
end

local function SweepDrops()
    if not Config.AutoCollectOrbs then
        return
    end
    local things = Workspace:FindFirstChild("__THINGS")
    local orbsFolder = things and things:FindFirstChild("Orbs")
    if not orbsFolder then
        return
    end

    local children = orbsFolder:GetChildren()
    if #children == 0 then
        return
    end

    local orbIds = Runtime.Cache.OrbSweepIds
    local seen = Runtime.Cache.OrbSweepSeen
    table.clear(orbIds)
    table.clear(seen)

    for _, orb in ipairs(children) do
        local numId = tonumber(orb.Name)
        if not numId then
            local rawId = orb:GetAttribute("OrbID") or orb:GetAttribute("id")
            numId = tonumber(rawId)
        end
        if numId and not seen[numId] then
            seen[numId] = true
            table.insert(orbIds, numId)
        end
        if #orbIds >= 50 then
            FireOrbsCollect(orbIds)
            table.clear(orbIds)
        end
    end
    if #orbIds > 0 then
        FireOrbsCollect(orbIds)
        table.clear(orbIds)
    end
end

-- ============================================================================
-- 8. TYCOON BUTTONS RUSH & COMPLETION CLAIM
-- ============================================================================
local function IsCriticalRootButton(btn)
    if btn.Optional == true then
        return false
    end
    if btn.Opens or btn.PathIndex or btn.Egg or btn.Pedestal then
        return true
    end
    if btn.Id == "UpgradeMachine" or btn.Id == "CocoaStand" or btn.Id == "GoldMachine" or btn.Id == "RainbowMachine"
        or btn.Id == "PetNetStore"
        or btn.Subclass == "IslandLuck" or btn.Subclass == "CoinsBoost" or btn.Subclass == "DamageBoost" then
        return true
    end
    if string.sub(btn.Id, 1, 12) == "OrchardChest" or string.sub(btn.Id, -5) == "_Luck" or string.find(btn.Id, "Pedestal", 1, true) then
        return true
    end
    return false
end

local function GetCriticalButtonSet(part2)
    local isP2 = part2 == true
    if Runtime.Cache.CriticalButtons ~= nil and Runtime.Cache.CriticalButtonsPart2 == isP2 then
        return Runtime.Cache.CriticalButtons
    end
    local set = {}
    local byId = Modules.ButtonsTypes and Modules.ButtonsTypes.BY_ID
    local list = Modules.ButtonsTypes and Modules.ButtonsTypes.BUTTONS
    if type(list) == "table" then
        local queue = {}
        for _, btn in ipairs(list) do
            local btnPart = btn.Part or 1
            local inScope = (btnPart == 1) or (isP2 and btnPart == 2)
            if type(btn) == "table" and btn.Id and inScope and IsCriticalRootButton(btn) then
                if not set[btn.Id] then
                    set[btn.Id] = true
                    table.insert(queue, btn)
                end
            end
        end
        local idx = 1
        while idx <= #queue do
            local curr = queue[idx]
            idx = idx + 1
            if type(curr.Required) == "table" and type(byId) == "table" then
                for _, reqId in ipairs(curr.Required) do
                    if not set[reqId] then
                        set[reqId] = true
                        local reqBtn = byId[reqId]
                        if type(reqBtn) == "table" then
                            table.insert(queue, reqBtn)
                        end
                    end
                end
            end
        end
    end
    Runtime.Cache.CriticalButtons = set
    Runtime.Cache.CriticalButtonsPart2 = isP2
    return set
end

local function GetButtonPriorityRank(btn, part2)
    if btn.Optional == true then
        return 4
    end
    if IsCriticalRootButton(btn) or GetCriticalButtonSet(part2)[btn.Id] then
        return 1
    end
    if btn.Id == "Merchant" then
        return 2
    end
    return 3
end

local function GetButtonPriceMult()
    if PT_Buttons and PT_Buttons.PriceMult then
        local ok, mult = pcall(PT_Buttons.PriceMult)
        if ok and type(mult) == "number" then
            return mult
        end
    end
    return tonumber(GetFlag("PumpkinTycoon_ButtonPriceMult", 1)) or 1
end

local function GetMinCriticalButtonPrice(buttons, plot)
    if not Modules.PumpkinButtonsUtil or not Modules.PumpkinButtonsUtil.Available then
        return nil
    end
    local targetPlot = plot or GetMyPlot()
    local part2 = Runtime.Helpers.IsPlotPart2Active(targetPlot)
    local zones = GetZoneCount(targetPlot)
    local priceMult = GetButtonPriceMult()
    local okAvail, avail = pcall(Modules.PumpkinButtonsUtil.Available, buttons, zones, part2, priceMult)
    if not okAvail or type(avail) ~= "table" then
        return nil
    end
    local minPrice = nil
    for _, btn in ipairs(avail) do
        if GetButtonPriorityRank(btn, part2) == 1 then
            local price = Modules.PumpkinButtonsUtil.Price(btn, priceMult)
            if type(price) == "number" and price > 0 and (not minPrice or price < minPrice) then
                minPrice = price
            end
        end
    end
    return minPrice
end

local EvaluateEarlyBootstrap -- Forward-declared for StepButtonsAndComplete Coin reservation

function Runtime.Helpers.TryClaimCompletionsAndRebirth(plot, buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths)
    local now = os.clock()

    if Config.AutoCompleteTycoon and tycoonComplete and not claimedComplete then
        local ok, res = pcall(plot.Invoke, plot, NET.Complete)
        if ok and res ~= false then
            Runtime.Helpers.InvalidatePlotSave(plot, VAR.Buttons)
            Log("INFO", "Claimed Tycoon completion reward (BT_Settle)!")
            buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths = GetProgressState(plot, true)
        end
    end

    if Config.AutoCompletePart2 ~= false and isPart2 and tycoonComplete and not claimedComplete2 and NET.Complete2 then
        if (now - (Runtime.Cache.LastComplete2FailAt or 0)) >= 15 then
            local ok2, res2, reason2 = pcall(plot.Invoke, plot, NET.Complete2)
            if ok2 and res2 ~= false then
                Runtime.Cache.LastComplete2FailAt = 0
                Runtime.Helpers.InvalidatePlotSave(plot, VAR.Buttons)
                Log("INFO", "Claimed Tycoon Part 2 completion reward (MH_Conclude)!")
                buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths = GetProgressState(plot, true)
            else
                Runtime.Cache.LastComplete2FailAt = now
                Log("DEBUG", "Part 2 completion claim skipped/failed: %s", tostring(reason2 or res2))
            end
        end
    end

    local targetReb = math.floor(tonumber(Config.TargetRebirths) or 0)
    local wantRebirth = (targetReb < 0) or (targetReb > 0 and rebirths < targetReb)
    if wantRebirth and isPart2 and tycoonComplete and NET.Rebirth
        and GetFlag("PumpkinTycoon_Rebirth", false) == true
        and (not Config.AutoCompleteTycoon or claimedComplete)
        and (now - (Runtime.Cache.LastRebirthFailAt or 0)) >= 10 then
        local okR, resR, reasonR, giftsR, newRebR = pcall(plot.Invoke, plot, NET.Rebirth)
        if okR and resR == true then
            Runtime.Cache.LastRebirthFailAt = 0
            Runtime.Helpers.InvalidatePlotSave(plot, VAR.Buttons)
            Runtime.Helpers.InvalidatePlotSave(plot, VAR.Rebirths)
            table.clear(Runtime.Cache.TargetEggCache)
            table.clear(Runtime.Cache.EarlyHatchedByEgg)
            table.clear(Runtime.Cache.EarlyCoinsSpentByEgg)
            Runtime.Cache.ReserveEarlyEggCost = 0
            Runtime.Cache.LastButtonsDoneForDecor = -1
            Runtime.Cache.LastCoinRateSampleAt = 0
            table.clear(Runtime.Cache.CoinRateSamples)
            Runtime.Cache.LastGrossCoins = nil
            Log("INFO", "Rebirth #%s completed (+%s Flannel Gifts). Resetting progression caches.",
                tostring(newRebR or (rebirths + 1)), tostring(giftsR or "?"))
            buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths = GetProgressState(plot, true)
        else
            Runtime.Cache.LastRebirthFailAt = now
            Log("DEBUG", "Rebirth failed/rejected: %s", tostring(reasonR or resR))
        end
    end

    return buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths
end

local function StepButtonsAndComplete(plot)
    if not plot or not Modules.PumpkinButtonsUtil then
        return nil, false, false, false, false, 0
    end

    local now = os.clock()
    if Runtime.Cache.Buttons ~= nil and (now - (Runtime.Cache.LastButtonsStepAt or 0)) < 0.5 then
        return Runtime.Cache.Buttons, Runtime.Stats.TycoonComplete, Runtime.Stats.CompletedClaimed,
            Runtime.Stats.Completed2Claimed, Runtime.Helpers.IsPlotPart2Active(plot), Runtime.Stats.Rebirths
    end
    Runtime.Cache.LastButtonsStepAt = now

    local buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths = GetProgressState(plot)

    buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths =
        Runtime.Helpers.TryClaimCompletionsAndRebirth(plot, buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths)

    if not Config.AutoBuyButtons then
        return buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths
    end

    local zones = GetZoneCount(plot)
    local priceMult = GetButtonPriceMult()
    local coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")

    if EvaluateEarlyBootstrap and not tycoonComplete then
        EvaluateEarlyBootstrap(plot, buttons)
    else
        Runtime.Cache.ReserveEarlyEggCost = 0
    end

    -- Burst buy all currently affordable unlocked buttons in progression priority order (Part 1 + Part 2)
    local boughtThisPass = 0
    while IsRunning() and boughtThisPass < 100 do
        if Config.RushButtonsFirst and not tycoonComplete and Runtime.Stats.IsHatching then
            break
        end
        local spendableCoins = math.max(0, coins - (Runtime.Cache.ReserveEarlyEggCost or 0))
        local avail = Modules.PumpkinButtonsUtil.Available(buttons, zones, isPart2, priceMult)
        local hasRank1 = false
        local minRank1Price = math.huge
        local candidates = {}
        for _, btn in ipairs(avail) do
            local skipOptional = (btn.Optional == true) and (not Config.BuyOptionalPart2Buttons or not tycoonComplete)
            if not skipOptional then
                local rank = GetButtonPriorityRank(btn, isPart2)
                local price = Modules.PumpkinButtonsUtil.Price(btn, priceMult)
                if rank == 1 then
                    hasRank1 = true
                    if price < minRank1Price then
                        minRank1Price = price
                    end
                end
                if price <= spendableCoins then
                    table.insert(candidates, { btn = btn, price = price, rank = rank })
                end
            end
        end
        local affordable = {}
        for _, item in ipairs(candidates) do
            -- Save coins for the next critical-path button instead of draining budget on cosmetic leaves
            if item.rank == 1 or not hasRank1 or item.price <= (minRank1Price * 0.05) then
                table.insert(affordable, item)
            end
        end
        if #affordable == 0 then
            break
        end

        table.sort(affordable, function(a, b)
            if a.rank ~= b.rank then
                return a.rank < b.rank
            end
            if a.price ~= b.price then
                return a.price < b.price
            end
            return a.btn.Id < b.btn.Id
        end)

        local pick = affordable[1]
        local ok, res = pcall(plot.Invoke, plot, NET.Buy, pick.btn.Id)
        if not ok or res == false then
            break
        end
        boughtThisPass = boughtThisPass + 1
        Runtime.Helpers.InvalidatePlotSave(plot, VAR.Buttons)
        table.clear(Runtime.Cache.TargetEggCache)
        Runtime.Helpers.RecordCoinsSpent(pick.price)
        Log("INFO", "Bought Button [%s] (%s) for %s Coins", pick.btn.Id, tostring(pick.btn.Display), tostring(pick.price))
        buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths = GetProgressState(plot, true)
        coins = Runtime.Stats.Coins
        if EvaluateEarlyBootstrap and not tycoonComplete then
            EvaluateEarlyBootstrap(plot, buttons)
        else
            Runtime.Cache.ReserveEarlyEggCost = 0
        end
        task.wait(0.02)
    end

    buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths =
        Runtime.Helpers.TryClaimCompletionsAndRebirth(plot, buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths)

    return buttons, tycoonComplete, claimedComplete, claimedComplete2, isPart2, rebirths
end

-- ============================================================================
-- 9. UPGRADES ENGINE (PUMPKIN TOKENS)
-- ============================================================================
local function GetUpgradeCostMult()
    if Modules.PumpkinUpgradesUtil and Modules.PumpkinUpgradesUtil.CostMult then
        local ok, mult = pcall(Modules.PumpkinUpgradesUtil.CostMult)
        if ok and type(mult) == "number" then
            return mult
        end
    end
    return 1
end

local function GetTrackNextInfo(trackKey)
    local row = Modules.UpgradesTypes and Modules.UpgradesTypes.ROWS and Modules.UpgradesTypes.ROWS[trackKey]
    if not row or not Modules.UpgradesTypes.Id then
        return nil
    end
    local tier = 0
    if Modules.EventUpgradeCmds and Modules.EventUpgradeCmds.GetTier then
        local ok, t = pcall(Modules.EventUpgradeCmds.GetTier, Modules.UpgradesTypes.Id(trackKey))
        if ok and type(t) == "number" then
            tier = t
        end
    end
    local maxTier = #row.Powers
    if tier >= maxTier then
        return nil
    end
    local baseCost = row.Costs[tier + 1]
    if not baseCost then
        return nil
    end
    local liveCost = math.max(1, math.ceil(baseCost * GetUpgradeCostMult()))
    return { track = trackKey, nextTier = tier + 1, baseCost = baseCost, cost = liveCost }
end

local function StepUpgrades(plot, buttons)
    if not Config.AutoUpgrades or not plot or not Modules.UpgradesTypes or not Modules.PumpkinButtonsUtil then
        return
    end
    local now = os.clock()
    if (now - (Runtime.Cache.LastUpgradesStepAt or 0)) < 1.5 then
        return
    end
    Runtime.Cache.LastUpgradesStepAt = now

    local machineButton = Modules.UpgradesTypes.BUTTON or "UpgradeMachine"
    if not Modules.PumpkinButtonsUtil.Owned(buttons, machineButton) then
        return
    end

    local tokens = GetCurrency((PT and PT.TOKENS) or "PumpkinTokens")
    Runtime.Stats.Tokens = tokens
    if tokens <= 0 then
        return
    end
    if Runtime.Cache.AllUpgradesMaxed and (now - (Runtime.Cache.AllUpgradesMaxedAt or 0)) < 15.0 then
        return
    end

    local catchupRatio = tonumber(Config.UpgradeCheapCatchupRatio) or 0
    local maxCheapTier1 = tonumber(Config.UpgradeCheapTier1MaxBaseCost) or 50
    local maxBuys = 15
    for _ = 1, maxBuys do
        if not IsRunning() then
            break
        end
        tokens = GetCurrency((PT and PT.TOKENS) or "PumpkinTokens")
        Runtime.Stats.Tokens = tokens
        if tokens <= 0 then
            break
        end

        local infos = {}
        local pendingCheapTier1 = nil
        local topCandidate = nil
        for _, trackKey in ipairs(Config.UpgradePriority or {}) do
            local info = GetTrackNextInfo(trackKey)
            if info then
                table.insert(infos, info)
                if not topCandidate then
                    topCandidate = info
                end
                if not pendingCheapTier1
                    and Config.UpgradeTier1CheapFirst
                    and info.nextTier == 1
                    and info.baseCost <= maxCheapTier1
                then
                    pendingCheapTier1 = info
                end
            end
        end

        if #infos == 0 then
            Runtime.Cache.AllUpgradesMaxed = true
            Runtime.Cache.AllUpgradesMaxedAt = os.clock()
            break
        end
        Runtime.Cache.AllUpgradesMaxed = false

        local selected = nil
        if pendingCheapTier1 then
            if tokens >= pendingCheapTier1.cost then
                selected = pendingCheapTier1
            end
        elseif topCandidate then
            for _, info in ipairs(infos) do
                if tokens >= info.cost then
                    if info == topCandidate then
                        selected = info
                        break
                    elseif catchupRatio > 0 and info.cost <= (topCandidate.cost * catchupRatio) then
                        selected = info
                        break
                    end
                end
            end
        end

        if not selected then
            break
        end

        local ok, res = pcall(plot.Invoke, plot, NET.UpgradeBuy, selected.track)
        if not ok or res == false then
            break
        end
        Runtime.Stats.Tokens = GetCurrency((PT and PT.TOKENS) or "PumpkinTokens")
        Log("INFO", "Upgraded [%s] to Tier %d for %s Tokens", selected.track, selected.nextTier, tostring(selected.cost))
        task.wait(0.04)
    end
end

-- ============================================================================
-- 10. CONSUMABLE BOOSTS, HOT COCOA STAND & FLANNEL GIFTS
-- ============================================================================
local function GetBoostTimerSeconds(boostId)
    if not Modules.BoostCmds or not Modules.BoostCmds.GetTimer then
        return 0
    end
    local ok, sec = pcall(Modules.BoostCmds.GetTimer, boostId)
    return (ok and type(sec) == "number") and sec or 0
end

function Runtime.Helpers.GetMaxBoostTier(plot)
    local bUtil = Modules.PumpkinBoostsUtil
    if bUtil and type(bUtil.PlayerMaxTier) == "function" then
        local ok, t = pcall(bUtil.PlayerMaxTier, LocalPlayer)
        if ok and type(t) == "number" and t >= 1 then
            return math.clamp(math.floor(t), 1, 3)
        end
    end
    if bUtil and type(bUtil.MaxTier) == "function" and plot then
        local ok, t = pcall(bUtil.MaxTier, plot)
        if ok and type(t) == "number" and t >= 1 then
            return math.clamp(math.floor(t), 1, 3)
        end
    end
    return Runtime.Helpers.IsPlotPart2Active(plot) and 3 or 2
end

local function StepConsumableBoosts(plot)
    if not Config.AutoConsumeBoosts or not Modules.PumpkinBoostsUtil or not Modules.Save or not Modules.Network then
        return
    end
    local now = os.clock()
    if (now - (Runtime.Cache.LastBoostsStepAt or 0)) < 1.5 then
        return
    end
    Runtime.Cache.LastBoostsStepAt = now

    local threshold = tonumber(Config.BoostRefreshSeconds) or 15
    local maxTier = Runtime.Helpers.GetMaxBoostTier(plot)
    local itemsMap = Modules.PumpkinBoostsUtil.ITEMS or {}
    local activeTierByAxis = {}
    local anyNeedsCheck = false
    for axis, itemName in pairs(itemsMap) do
        if Config.AllowedConsumableBoosts[itemName] ~= false then
            local activeTier = 0
            for tier = maxTier, 1, -1 do
                local boostId = Modules.PumpkinBoostsUtil.Id(axis, tier)
                if boostId and GetBoostTimerSeconds(boostId) > threshold then
                    activeTier = tier
                    break
                end
            end
            activeTierByAxis[axis] = activeTier
            if activeTier < maxTier then
                anyNeedsCheck = true
            end
        end
    end
    if not anyNeedsCheck then
        return
    end

    local okSave, saveData = pcall(Modules.Save.Get)
    local consumables = okSave and saveData and saveData.Inventory and saveData.Inventory.Consumable
    if type(consumables) ~= "table" or next(consumables) == nil then
        return
    end

    local itemToAxis = {}
    for axis, itemName in pairs(itemsMap) do
        itemToAxis[itemName] = axis
    end

    -- Collect highest-tier matching event consumable per axis (Tier 3 > Tier 2 > Tier 1)
    local bestByAxis = {}
    for uid, data in pairs(consumables) do
        if type(data) == "table" then
            local itemName = tostring(data.id or data._id or "")
            local axis = itemToAxis[itemName]
            if axis and Config.AllowedConsumableBoosts[itemName] ~= false then
                local tier = math.clamp(math.floor(tonumber(data.tn or data.tier or 1) or 1), 1, maxTier)
                local prev = bestByAxis[axis]
                if not prev or tier > prev.tier then
                    bestByAxis[axis] = {
                        uid = tostring(uid),
                        itemName = itemName,
                        axis = axis,
                        tier = tier,
                        boostId = Modules.PumpkinBoostsUtil.Id(axis, tier),
                    }
                end
            end
        end
    end

    local ordered = {}
    for _, cand in pairs(bestByAxis) do
        table.insert(ordered, cand)
    end
    table.sort(ordered, function(a, b)
        if a.tier ~= b.tier then
            return a.tier > b.tier
        end
        return a.axis < b.axis
    end)

    for _, cand in ipairs(ordered) do
        local activeTier = activeTierByAxis[cand.axis] or 0
        local shouldUse = (activeTier == 0) or (cand.tier > activeTier)
        local lastAt = Runtime.Cache.BoostConsumeCooldown[cand.boostId] or 0
        if shouldUse and (now - lastAt) >= 3.0 and GetBoostTimerSeconds(cand.boostId) <= threshold then
            local cOk, cRes = pcall(Modules.Network.Invoke, "Consumables_Consume", cand.uid, 1)
            if cOk and cRes ~= false then
                Runtime.Cache.BoostConsumeCooldown[cand.boostId] = now
                Log("INFO", "Consumed %s Tier %d (%s)", cand.itemName, cand.tier, cand.boostId)
                task.wait(0.05)
            end
        end
    end
end

function Runtime.Helpers.GetActiveFruitCount(targetFruitId)
    local fCmds = Modules.FruitCmds
    if not fCmds or type(fCmds.GetActiveFruits) ~= "function" then
        return 0
    end
    local ok, active = pcall(fCmds.GetActiveFruits)
    if not ok or type(active) ~= "table" then
        return 0
    end
    if type(targetFruitId) == "string" then
        local entry = active[targetFruitId]
        if type(entry) ~= "table" then
            return 0
        end
        local sCnt = type(entry.Shiny) == "table" and #entry.Shiny or 0
        local nCnt = type(entry.Normal) == "table" and #entry.Normal or 0
        return sCnt + nCnt
    end
    local total = 0
    for _, entry in pairs(active) do
        if type(entry) == "table" then
            total = total + (type(entry.Shiny) == "table" and #entry.Shiny or 0) + (type(entry.Normal) == "table" and #entry.Normal or 0)
        end
    end
    return total
end

function Runtime.Helpers.StepConsumeFruits()
    local fCmds = Modules.FruitCmds
    if not Config.AutoConsumeFruits or not fCmds or not Modules.Save or type(fCmds.Consume) ~= "function" then
        return
    end
    local now = os.clock()
    if (now - (Runtime.Cache.LastFruitsStepAt or 0)) < 1.5 then
        return
    end
    Runtime.Cache.LastFruitsStepAt = now

    local targetStack = math.clamp(math.floor(tonumber(Config.FruitTargetStack) or 20), 1, 20)
    if type(fCmds.ComputeFruitQueueLimit) == "function" then
        local okL, lim = pcall(fCmds.ComputeFruitQueueLimit)
        if okL and type(lim) == "number" and lim >= 1 then
            targetStack = math.clamp(math.floor(tonumber(Config.FruitTargetStack) or 20), 1, math.floor(lim))
        end
    end
    local minMissing = math.max(1, math.floor(tonumber(Config.FruitMinRefillMissing) or 4))
    local cooldownSec = math.max(2, tonumber(Config.FruitConsumeCooldownSec) or 6)
    local allowed = Config.AllowedFruits

    if type(allowed) == "table" then
        local anyFruitNeedsEat = false
        for fruitId, isAllowed in pairs(allowed) do
            if isAllowed == true then
                local lastAt = Runtime.Cache.FruitConsumeCooldown[fruitId] or 0
                if (now - lastAt) >= cooldownSec then
                    local activeCnt = Runtime.Helpers.GetActiveFruitCount(fruitId)
                    local missing = targetStack - activeCnt
                    if missing > 0 and (activeCnt == 0 or missing >= minMissing) then
                        anyFruitNeedsEat = true
                        break
                    end
                end
            end
        end
        if not anyFruitNeedsEat then
            return
        end
    end

    local okSave, saveData = pcall(Modules.Save.Get)
    local invFruits = okSave and type(saveData) == "table" and saveData.Inventory and saveData.Inventory.Fruit
    if type(invFruits) ~= "table" or next(invFruits) == nil then
        return
    end

    local stacks = {}
    for uid, data in pairs(invFruits) do
        if type(data) == "table" and type(data.id) == "string" and (allowed == nil or allowed[data.id] == true) then
            local amt = math.max(1, math.floor(tonumber(data._am) or 1))
            table.insert(stacks, {
                uid = tostring(uid),
                id = data.id,
                amt = amt,
                shiny = data.sh == true,
            })
        end
    end
    if #stacks == 0 then
        return
    end
    table.sort(stacks, function(a, b)
        if a.id ~= b.id then
            return a.id < b.id
        end
        if a.shiny ~= b.shiny then
            return a.shiny and not b.shiny
        end
        return a.uid < b.uid
    end)

    for _, st in ipairs(stacks) do
        local lastAt = Runtime.Cache.FruitConsumeCooldown[st.id] or 0
        if (now - lastAt) >= cooldownSec then
            local activeCnt = Runtime.Helpers.GetActiveFruitCount(st.id)
            local missing = targetStack - activeCnt
            if missing > 0 and (activeCnt == 0 or missing >= minMissing) then
                local maxCan = missing
                if type(fCmds.GetMaxConsume) == "function" then
                    local okM, lim = pcall(fCmds.GetMaxConsume, st.uid)
                    if okM and type(lim) == "number" then
                        maxCan = math.min(maxCan, math.floor(lim))
                    end
                end
                local eatAmt = math.min(missing, maxCan, st.amt)
                if eatAmt >= 1 then
                    local cOk = pcall(fCmds.Consume, st.uid, eatAmt)
                    if cOk then
                        Runtime.Cache.FruitConsumeCooldown[st.id] = now
                        Log("INFO", "Consumed %dx %s (%d->%d/%d)",
                            eatAmt, st.id, activeCnt, activeCnt + eatAmt, targetStack)
                        task.wait(0.05)
                    end
                end
            end
        end
    end
end

local function StepHotCocoaStand(plot, buttons, tycoonComplete)
    if not Config.AutoCocoaStand or not plot or not Modules.PumpkinCocoaUtil or not Modules.PumpkinBoostsUtil then
        return
    end
    if not Modules.PumpkinButtonsUtil or not Modules.PumpkinButtonsUtil.Owned(buttons, Modules.PumpkinCocoaUtil.BUTTON) then
        return
    end
    local now = os.clock()
    if now - (Runtime.Cache.LastCocoaCheckAt or 0) < 1.5 then
        return
    end
    Runtime.Cache.LastCocoaCheckAt = now

    if now - (Runtime.Cache.LastCocoaFailAt or 0) < 15 then
        return
    end

    if Config.CocoaRequireButtonsComplete and not tycoonComplete then
        return
    end

    if not tycoonComplete then
        local minIncome = tonumber(Config.CocoaMinIncomePerSec) or 3500000
        local sustainedOk = Runtime.Helpers.IsIncomeSustainedForCocoa(minIncome)
        if not sustainedOk then
            return
        end
    end

    local coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
    Runtime.Stats.Coins = coins
    local activateCoins = tonumber(Config.CocoaActivateCoins) or 0
    local spareCoins = tonumber(Config.CocoaMinSpareCoins) or 0
    if coins < activateCoins then
        return
    end

    local tier = Modules.PumpkinCocoaUtil.TIER or 1
    local costPerMin = Modules.PumpkinCocoaUtil.CostPerMinute and Modules.PumpkinCocoaUtil.CostPerMinute(tier)
    if type(costPerMin) ~= "number" or costPerMin <= 0 then
        return
    end

    local maintainSec = (tonumber(Config.CocoaMaintainMinutes) or 2) * 60
    local stepMin = math.max(1, math.floor(tonumber(Config.CocoaBuyStepMinutes) or 2))
    local tankSec = (Modules.PumpkinCocoaUtil.TankSeconds and Modules.PumpkinCocoaUtil.TankSeconds()) or (720 * 60)
    local liveCps = math.max(tonumber(Runtime.Stats.CoinsPerSec) or 0, select(1, Runtime.Helpers.GetWindowCps(60)) or 0)
    local buyBatchMin = (coins >= 15e9 and liveCps >= 20e6) and math.max(stepMin, 10) or stepMin

    local axes
    if tycoonComplete then
        axes = Config.CocoaAxes or {}
    else
        axes = {}
        local seenAxis = {}
        for _, a in ipairs(Config.CocoaRushAxes or { "Coins" }) do
            if not seenAxis[a] then
                seenAxis[a] = true
                table.insert(axes, a)
            end
        end
        local dmgMinCps = tonumber(Config.CocoaRushDamageMinIncomePerSec) or 15000000
        if not seenAxis.Damage and liveCps >= dmgMinCps then
            seenAxis.Damage = true
            table.insert(axes, "Damage")
        end
        local luckMinCps = tonumber(Config.CocoaRushLuckMinIncomePerSec) or 30000000
        if not seenAxis.IslandLuck and liveCps >= luckMinCps then
            seenAxis.IslandLuck = true
            table.insert(axes, "IslandLuck")
        end
    end

    local pending = {}
    local simCoins = coins
    for _, axis in ipairs(axes) do
        if simCoins < activateCoins then
            break
        end
        local boostId = Modules.PumpkinBoostsUtil.Id(axis, tier)
        local validOffer = (not Modules.PumpkinCocoaUtil.Offer) or (Modules.PumpkinCocoaUtil.Offer(boostId) ~= nil)
        if validOffer then
            local remaining = GetBoostTimerSeconds(boostId)
            local axisTotal = Runtime.Helpers.GetAxisBoostSeconds and Runtime.Helpers.GetAxisBoostSeconds(axis) or remaining
            if math.max(remaining, axisTotal) < maintainSec then
                local needMin = math.max(1, math.ceil((maintainSec - remaining) / 60))
                local wantMin = (buyBatchMin > stepMin) and buyBatchMin or math.min(stepMin, needMin)
                local maxTankMin = math.floor(math.max(0, tankSec - remaining) / 60)
                local affordableMin = math.floor(math.max(0, simCoins - spareCoins) / costPerMin)
                local buyMin = math.min(wantMin, maxTankMin, affordableMin)
                if buyMin >= 1 then
                    table.insert(pending, { boostId = boostId, buyMin = buyMin })
                    simCoins = simCoins - (buyMin * costPerMin)
                end
            end
        end
    end
    if #pending == 0 then
        return
    end

    WithMachinePad(plot, Modules.PumpkinCocoaUtil.MACHINE, Modules.PumpkinCocoaUtil.Range, function()
        for _, req in ipairs(pending) do
            if not IsRunning() then
                break
            end
            local ok, res, reason = pcall(plot.Invoke, plot, NET.CocoaBuyTime, req.boostId, req.buyMin)
            if ok and res == true then
                Runtime.Cache.LastCocoaFailAt = 0
                Runtime.Helpers.RecordCoinsSpent(req.buyMin * costPerMin)
                coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
                Runtime.Stats.Coins = coins
                Log("INFO", "Bought %dm Cocoa [%s] (%s Coins/min)", req.buyMin, tostring(req.boostId), tostring(costPerMin))
                task.wait(0.05)
            else
                Runtime.Cache.LastCocoaFailAt = os.clock()
                Log("DEBUG", "Cocoa buy failed [%s x%dm]: %s", tostring(req.boostId), req.buyMin, tostring(reason or res))
                break
            end
        end
    end)
end

local function BuildGiftPositions(amount)
    if Modules.LootboxLocation and Modules.LootboxLocation.ComputePositions and Modules.LootboxTypes then
        local ok, posList = pcall(
            Modules.LootboxLocation.ComputePositions,
            Modules.LootboxTypes.PlacementConfig,
            amount,
            {}
        )
        if ok and type(posList) == "table" and #posList == amount then
            return posList
        end
    end

    local char, hrp = GetCharacter()
    if not hrp then
        return nil
    end
    local center = hrp.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = char and { char } or {}

    local positions = {}
    local spacing = (Modules.LootboxTypes and Modules.LootboxTypes.PlacementConfig and tonumber(Modules.LootboxTypes.PlacementConfig.eggSpacingRadius)) or 3.5
    local radius = (amount > 1) and math.max(10, spacing / math.sin(math.pi / amount) + 1) or 10
    for i = 1, amount do
        local angle = (math.pi * 2 * i) / amount
        local rx = center.X + math.cos(angle) * radius
        local rz = center.Z + math.sin(angle) * radius
        local hit = Workspace:Raycast(Vector3.new(rx, center.Y + 15, rz), Vector3.new(0, -80, 0), rayParams)
        local gy = hit and hit.Position.Y or (center.Y - 3)
        table.insert(positions, Vector3.new(rx, gy, rz))
    end
    return positions
end

local function StepOpenFlannelGifts()
    if not Config.AutoOpenGifts or not Modules.Network then
        return
    end
    if Workspace:GetAttribute("PumpkinTycoonGiftOpener") ~= true then
        return
    end
    if Modules.PumpkinBoostsUtil and type(Modules.PumpkinBoostsUtil.Enabled) == "function" then
        local okB, bEnabled = pcall(Modules.PumpkinBoostsUtil.Enabled)
        if okB and not bEnabled then
            return
        end
    end
    local now = os.clock()
    if (now - (Runtime.Cache.LastGiftsStepAt or 0)) < 1.5 and (now - (Runtime.Cache.LastGiftAttemptAt or 0)) >= 0.5 then
        -- Throttle idle polling to 1.5s unless we just opened a gift batch with more waiting
        if not Runtime.Cache.HasMoreGiftsPending then
            return
        end
    end
    if now - (Runtime.Cache.LastGiftAttemptAt or 0) < 0.25 then
        return
    end
    Runtime.Cache.LastGiftsStepAt = now

    local giftName = (Modules.PumpkinGiftUtil and Modules.PumpkinGiftUtil.ID)
        or (Modules.ButtonsTypes and Modules.ButtonsTypes.COMPLETION_GIFT)
        or "Flannel Gift"
    local giftUid, giftAmt = nil, 0

    local readSaveOk = false
    if Modules.Save and Modules.Save.Get then
        local okSave, saveData = pcall(Modules.Save.Get)
        if okSave and type(saveData) == "table" then
            readSaveOk = true
            local inv = saveData.Inventory
            local boxes = type(inv) == "table" and inv.Lootbox or nil
            if type(boxes) ~= "table" or next(boxes) == nil then
                Runtime.Cache.GiftEmptyBoxesRef = boxes
                Runtime.Cache.GiftBagDirty = false
                Runtime.Cache.HasMoreGiftsPending = false
                return
            end
            if Runtime.Cache.GiftEmptyBoxesRef == boxes and not Runtime.Cache.GiftBagDirty then
                Runtime.Cache.HasMoreGiftsPending = false
                return
            end
            for uid, d in pairs(boxes) do
                if type(d) == "table" and (d.id == giftName or d._id == giftName) then
                    local am = tonumber(d._am) or 1
                    if am >= 1 then
                        giftUid = tostring(uid)
                        giftAmt = am
                        break
                    end
                end
            end
            if not giftUid then
                Runtime.Cache.GiftEmptyBoxesRef = boxes
                Runtime.Cache.GiftBagDirty = false
                Runtime.Cache.HasMoreGiftsPending = false
                return
            end
        end
    end

    if not readSaveOk and Modules.LootboxItem then
        pcall(function()
            local list = Modules.LootboxItem(giftName):FindAny()
            local first = list and list[1]
            if first then
                giftUid = first:GetUID()
                giftAmt = first:GetAmount()
            end
        end)
    end

    if not giftUid or giftAmt < 1 then
        Runtime.Cache.HasMoreGiftsPending = false
        return
    end

    local count = math.clamp(math.floor(math.min(giftAmt, Config.GiftBatchAmount or 8)), 1, 8)
    local positions = BuildGiftPositions(count)
    if not positions then
        return
    end

    -- Part 2 requires 4th arg cardShown matching LocalPlayer:GetAttribute("PumpkinTycoonGiftNets") == true
    local netsAttr = (Modules.PumpkinGiftUtil and Modules.PumpkinGiftUtil.NETS_ATTRIBUTE) or "PumpkinTycoonGiftNets"
    local sentNets = LocalPlayer:GetAttribute(netsAttr) == true
    if Modules.PumpkinGiftUtil then
        Modules.PumpkinGiftUtil.cardShown = sentNets
    end

    Runtime.Cache.LastGiftAttemptAt = os.clock()
    local ok, res, errMsg = pcall(Modules.Network.Invoke, NET.GiftOpen, giftUid, count, positions, sentNets)
    if ok and res == true then
        Runtime.Cache.GiftEmptyBoxesRef = nil
        Runtime.Cache.GiftBagDirty = true
        Runtime.Cache.HasMoreGiftsPending = (giftAmt > count)
        Runtime.Stats.GiftsOpened = Runtime.Stats.GiftsOpened + count
        Log("INFO", "Opened %dx %s (Total: %d)", count, giftName, Runtime.Stats.GiftsOpened)
    else
        Runtime.Cache.HasMoreGiftsPending = false
        Runtime.Cache.LastGiftAttemptAt = os.clock() + 3.0
        Log("DEBUG", "Failed to open %dx %s (nets=%s): %s", count, giftName, tostring(sentNets), tostring(errMsg or res))
    end
end

-- ============================================================================
-- 11. EGG HATCHER (SMART EARLY BOOTSTRAP + POST-COMPLETION ZONE 5 EGG)
-- ============================================================================
local function SuppressEggAnimation()
    if not Config.HatchDisableAnimation then
        return
    end
    if Workspace:GetAttribute("GlobalInstantHatch") ~= true then
        pcall(Workspace.SetAttribute, Workspace, "GlobalInstantHatch", true)
    end
    local vars = Modules.Variables
    if type(vars) == "table" then
        if vars.OpeningEgg ~= 0 then
            vars.OpeningEgg = 0
        end
        if vars.MessageOpen ~= false then
            vars.MessageOpen = false
        end
    end
end

local function GetEggPrice(eggName)
    local isPart2Egg = (eggName == "Pine Woods Egg" or eggName == "Maple Creek Egg" or eggName == "Golden Ridge Egg")
    local mult1 = tonumber(GetFlag("PumpkinTycoon_EggCostMult", 1)) or 1
    local mult2 = isPart2Egg and (tonumber(GetFlag("PumpkinTycoon_EggCostMultP2", 1)) or 1) or 1
    local effectiveMult = math.max(0.01, mult1 * mult2)
    local cacheKey = tostring(eggName) .. "|" .. tostring(effectiveMult)
    if Runtime.Cache.EggCostCache[cacheKey] then
        return Runtime.Cache.EggCostCache[cacheKey]
    end
    local dirEggs = Modules.Directory and Modules.Directory.Eggs
    local info = dirEggs and rawget(dirEggs, eggName)
    local cost = info and (info.overrideCost or info.cost)
    if type(cost) == "number" and cost > 0 then
        local finalCost = math.max(1, math.round(cost * effectiveMult))
        Runtime.Cache.EggCostCache[cacheKey] = finalCost
        return finalCost
    end
    local fallbacks = {
        ["Cocoa Cabin Egg"] = 200,
        ["Apple Orchard Egg"] = 1000,
        ["Hayride Hill Egg"] = 4000,
        ["Cider Mill Egg"] = 8000,
        ["Golden Grove Egg"] = 16000,
        ["Pine Woods Egg"] = 128000,
        ["Maple Creek Egg"] = 1024000,
        ["Golden Ridge Egg"] = 8192000,
    }
    return math.max(1, math.round((fallbacks[eggName] or 16000) * effectiveMult))
end

local function GetEggCommonPetId(eggName)
    local dirEggs = Modules.Directory and Modules.Directory.Eggs
    local info = dirEggs and rawget(dirEggs, eggName)
    local bestPetId, bestWeight = nil, -1
    if info and type(info.pets) == "table" then
        for _, entry in ipairs(info.pets) do
            local pname = type(entry) == "table" and entry[1] or nil
            local weight = type(entry) == "table" and tonumber(entry[2]) or 0
            if type(pname) == "string" and weight and weight > bestWeight then
                bestWeight = weight
                bestPetId = pname
            end
        end
    end
    return bestPetId
end

function Runtime.Helpers.IsDamagePart2Active()
    local ptd = Modules.PumpkinDamageUtil
    if ptd and type(ptd.Scope) == "function" then
        local okS, resS = pcall(ptd.Scope, LocalPlayer)
        if okS and type(resS) == "boolean" then
            return resS
        end
    end
    if ptd and type(ptd.Part2) == "function" then
        local okP, resP = pcall(ptd.Part2)
        if okP and resP == true then
            return true
        end
    end
    return Runtime.Cache.CriticalButtonsPart2 == true
end

function Runtime.Helpers.GetPetEventDamage(data, inst, pd)
    if type(data) ~= "table" or type(data.id) ~= "string" then
        return 0, false
    end
    local ptd = Modules.PumpkinDamageUtil
    local exLevel = (pd and type(pd.exclusiveLevel) == "number" and pd.exclusiveLevel > 0) and pd.exclusiveLevel or nil
    if not exLevel then
        if (pd and pd.gargantuan == true) or string.sub(data.id, 1, 11) == "Gargantuan " then
            exLevel = 6
        elseif (pd and pd.titanic == true) or string.sub(data.id, 1, 8) == "Titanic " then
            exLevel = 5
        elseif (pd and pd.huge == true) or string.sub(data.id, 1, 5) == "Huge " then
            exLevel = 4
        elseif inst and type(inst.GetExclusiveLevel) == "function" then
            local okEx, lv = pcall(inst.GetExclusiveLevel, inst)
            if okEx and type(lv) == "number" and lv > 0 then
                exLevel = lv
            end
        end
    end

    if exLevel and exLevel > 0 then
        if inst and ptd and type(ptd.ExclusiveMult) == "function" then
            local okEm, em = pcall(ptd.ExclusiveMult, inst)
            if okEm and type(em) == "number" and em > 0 then
                return em, true
            end
        end
        if exLevel < 4 then
            local cappedTbl = ptd and type(ptd.EXCLUSIVE_MULTS) == "table" and ptd.EXCLUSIVE_MULTS or nil
            local mult = (cappedTbl and tonumber(cappedTbl[exLevel]))
                or (exLevel == 1 and 0.55 or (exLevel == 2 and 0.60 or 0.65))
            return mult, true
        end
        local chaseMults = nil
        if ptd and type(ptd.ChaseMults) == "function" then
            local okC, resC = pcall(ptd.ChaseMults)
            if okC and type(resC) == "table" then
                chaseMults = resC
            end
        end
        local varMults = nil
        if ptd and type(ptd.ExclusiveVariants) == "function" then
            local okV, resV = pcall(ptd.ExclusiveVariants)
            if okV and type(resV) == "table" then
                varMults = resV
            end
        end
        local idx = math.clamp(math.floor(exLevel), 4, 6) - 3
        local baseMult = (chaseMults and tonumber(chaseMults[idx]))
            or (idx == 1 and 1.1 or (idx == 2 and 2.0 or 4.0))
        local varMult = 1
        if data.pt == 1 then
            varMult = varMult * ((varMults and tonumber(varMults[1])) or 1.1)
        elseif data.pt == 2 then
            varMult = varMult * ((varMults and tonumber(varMults[2])) or 1.25)
        end
        if data.sh == true then
            varMult = varMult * ((varMults and tonumber(varMults[3])) or 1.3)
        end
        local mult = baseMult * varMult
        local capMult = chaseMults and tonumber(chaseMults[idx + 1]) or nil
        if capMult and capMult > 0 then
            mult = math.min(mult, capMult)
        end
        return mult, true
    end

    local part2 = Runtime.Helpers.IsDamagePart2Active()
    local evMap = Runtime.Cache.EventPetsRankMap
    if (evMap == nil or Runtime.Cache.EventPetsRankMapPart2 ~= part2) and ptd and type(ptd.EventPets) == "function" then
        local okMap, resMap = pcall(ptd.EventPets, part2)
        if okMap and type(resMap) == "table" then
            evMap = resMap
            Runtime.Cache.EventPetsRankMap = resMap
            if Runtime.Cache.EventPetsRankMapPart2 ~= part2 then
                Runtime.Cache.EventPetsRankMapPart2 = part2
                table.clear(Runtime.Cache.EggCommonEventDmgCache)
            end
        end
    end

    local rank = type(evMap) == "table" and evMap[data.id] or nil
    if rank then
        if ptd and type(ptd.PetHit) == "function" and inst then
            local okHit, dmg = pcall(ptd.PetHit, inst, 0, nil, part2)
            if okHit and type(dmg) == "number" and dmg > 0 then
                return dmg, false
            end
        end
        local flat = (ptd and type(ptd.Flat) == "function" and ptd.Flat()) or 10
        local base = flat + math.max(1, 5 * (3 ^ math.max(0, rank - 1)))
        local mult = (data.pt == 1 and 2 or (data.pt == 2 and 4 or 1)) * (data.sh == true and 2 or 1)
        return math.ceil(base * mult), false
    end

    if type(evMap) == "table" then
        return (ptd and type(ptd.Flat) == "function" and ptd.Flat()) or 10, false
    end

    local pw = 0
    if inst and inst.CalculatePower then
        local okP, val = pcall(inst.CalculatePower, inst)
        if okP and type(val) == "number" then
            pw = val
        end
    end
    if pw <= 0 and pd then
        pw = (type(pd.cachedPower) == "table" and tonumber(pd.cachedPower[1])) or tonumber(pd.power) or 1
    end
    return pw, false
end

function Runtime.Helpers.GetEggCommonEventDamage(eggName)
    local part2 = Runtime.Helpers.IsDamagePart2Active()
    if Runtime.Cache.EggCommonEventDmgPart2 ~= part2 then
        Runtime.Cache.EggCommonEventDmgPart2 = part2
        table.clear(Runtime.Cache.EggCommonEventDmgCache)
    end
    if Runtime.Cache.EggCommonEventDmgCache[eggName] ~= nil then
        return Runtime.Cache.EggCommonEventDmgCache[eggName]
    end
    local bestPetId = GetEggCommonPetId(eggName)
    local dmg = 0
    if bestPetId then
        local inst = nil
        if Modules.PetItem and type(Modules.PetItem.From) == "function" then
            local okI, resI = pcall(Modules.PetItem.From, Modules.PetItem, { id = bestPetId })
            if okI and resI then
                inst = resI
            end
        end
        local petsDir = Modules.Directory and Modules.Directory.Pets
        local pd = type(petsDir) == "table" and rawget(petsDir, bestPetId) or nil
        dmg = select(1, Runtime.Helpers.GetPetEventDamage({ id = bestPetId }, inst, pd))
    end
    Runtime.Cache.EggCommonEventDmgCache[eggName] = dmg
    return dmg
end

function Runtime.Helpers.GetEggUncommonEventDamage(eggName)
    local part2 = Runtime.Helpers.IsDamagePart2Active()
    if Runtime.Cache.EggUncommonEventDmgPart2 ~= part2 then
        Runtime.Cache.EggUncommonEventDmgPart2 = part2
        Runtime.Cache.EggUncommonEventDmgCache = {}
    end
    local cache = Runtime.Cache.EggUncommonEventDmgCache
    if not cache then
        cache = {}
        Runtime.Cache.EggUncommonEventDmgCache = cache
    end
    if cache[eggName] ~= nil then
        return cache[eggName]
    end
    local dirEggs = Modules.Directory and Modules.Directory.Eggs
    local info = dirEggs and rawget(dirEggs, eggName)
    local petsDir = Modules.Directory and Modules.Directory.Pets
    local bestDmg = 0
    if info and type(info.pets) == "table" then
        for _, entry in ipairs(info.pets) do
            local pname = type(entry) == "table" and entry[1] or nil
            local weight = type(entry) == "table" and tonumber(entry[2]) or 0
            -- Consider realistic bootstrap pets (weight >= 5%, e.g. 90% common & 10% uncommon such as Cocoa Husky R7)
            if type(pname) == "string" and weight >= 5 then
                local pd = type(petsDir) == "table" and rawget(petsDir, pname) or nil
                local isChase = (pd and (pd.huge == true or pd.titanic == true or pd.gargantuan == true))
                    or string.sub(pname, 1, 5) == "Huge "
                    or string.sub(pname, 1, 8) == "Titanic "
                    or string.sub(pname, 1, 11) == "Gargantuan "
                if not isChase then
                    local inst = nil
                    if Modules.PetItem and type(Modules.PetItem.From) == "function" then
                        local okI, resI = pcall(Modules.PetItem.From, Modules.PetItem, { id = pname })
                        if okI and resI then
                            inst = resI
                        end
                    end
                    local dmg = select(1, Runtime.Helpers.GetPetEventDamage({ id = pname }, inst, pd))
                    if type(dmg) == "number" and dmg > bestDmg then
                        bestDmg = dmg
                    end
                end
            end
        end
    end
    cache[eggName] = bestDmg
    return bestDmg
end

local function GetEggCommonPower(eggName)
    if Runtime.Cache.EggBasePowerCache[eggName] ~= nil then
        return Runtime.Cache.EggBasePowerCache[eggName]
    end
    local bestPetId = GetEggCommonPetId(eggName)
    local power = 0
    if bestPetId then
        if Modules.PetItem then
            local okI, inst = pcall(Modules.PetItem, bestPetId, "preview", { id = bestPetId })
            if okI and inst and inst.CalculatePower then
                local okP, pw = pcall(inst.CalculatePower, inst)
                if okP and type(pw) == "number" and pw > 0 then
                    power = pw
                end
            end
        end
        if power <= 0 and Modules.Directory and Modules.Directory.Pets then
            local pd = rawget(Modules.Directory.Pets, bestPetId)
            if pd then
                power = (type(pd.cachedPower) == "table" and tonumber(pd.cachedPower[1]))
                    or tonumber(pd.power)
                    or 0
            end
        end
    end
    Runtime.Cache.EggBasePowerCache[eggName] = power
    return power
end

local function SafeDirLookup(dirTable, key)
    if type(dirTable) ~= "table" or key == nil then
        return nil
    end
    local rawVal = rawget(dirTable, key)
    if rawVal ~= nil then
        return rawVal
    end
    if getmetatable(dirTable) ~= nil then
        local ok, val = pcall(function()
            return dirTable[key]
        end)
        if ok then
            return val
        end
    end
    return nil
end

local function ResolvePetItem(uid)
    local petItemCls = Modules.PetItem
    if not petItemCls or uid == nil or type(petItemCls.Get) ~= "function" then
        return nil
    end
    local okG, inst = pcall(petItemCls.Get, petItemCls, uid)
    if okG and inst then
        return inst
    end
    return nil
end

local function GetTeamPowerSnapshot(forceRefresh)
    local now = os.clock()
    if not forceRefresh and Runtime.Cache.TeamPowerSnapshot and (now - Runtime.Cache.TeamPowerSnapshotAt) < 0.4 then
        return Runtime.Cache.TeamPowerSnapshot
    end
    local maxEquip = 4
    if Modules.PetCmds and Modules.PetCmds.GetMaxEquipped then
        local okM, m = pcall(Modules.PetCmds.GetMaxEquipped)
        if okM and type(m) == "number" and m >= 1 then
            maxEquip = math.floor(m)
        end
    end

    local okSave, saveData = false, nil
    if Modules.Save and Modules.Save.Get then
        okSave, saveData = pcall(Modules.Save.Get)
    end
    local invPets = okSave and type(saveData) == "table" and saveData.Inventory and saveData.Inventory.Pet
    local petsDir = Modules.Directory and Modules.Directory.Pets
    local entries = Runtime.Cache.TeamEntriesScratch
    if not entries then
        entries = {}
        Runtime.Cache.TeamEntriesScratch = entries
    else
        table.clear(entries)
    end
    local bestNonHugePw = 0
    local entryIdx = 0
    local entryPool = Runtime.Cache.TeamEntryPool
    if not entryPool then
        entryPool = {}
        Runtime.Cache.TeamEntryPool = entryPool
    end

    if type(invPets) == "table" then
        for uid, data in pairs(invPets) do
            if type(data) == "table" and type(data.id) == "string" then
                local pd = SafeDirLookup(petsDir, data.id)
                local inst = ResolvePetItem(uid)
                local pw, scaleWithBest = Runtime.Helpers.GetPetEventDamage(data, inst, pd)
                if not scaleWithBest and pw > bestNonHugePw then
                    bestNonHugePw = pw
                end
                local amt = math.min(maxEquip, math.max(1, math.floor(tonumber(data._am) or 1)))
                entryIdx = entryIdx + 1
                local rec = entryPool[entryIdx]
                if not rec then
                    rec = {}
                    entryPool[entryIdx] = rec
                end
                rec.pw = pw
                rec.scaleWithBest = scaleWithBest
                rec.amt = amt
                entries[entryIdx] = rec
            end
        end
    end

    local slotPowers = Runtime.Cache.TeamSlotPowersScratch
    if not slotPowers then
        slotPowers = {}
        Runtime.Cache.TeamSlotPowersScratch = slotPowers
    else
        table.clear(slotPowers)
    end
    for _, e in ipairs(entries) do
        -- Huge/Titanic/Gargantuan pets scale off bestNonHuge EventDamage
        local effPw = e.scaleWithBest and math.ceil(math.max(10, bestNonHugePw) * e.pw) or e.pw
        for _ = 1, e.amt do
            table.insert(slotPowers, effPw)
        end
    end
    table.sort(slotPowers, function(a, b)
        return a > b
    end)

    local best = slotPowers[1] or 0
    local weakest = (#slotPowers >= maxEquip) and slotPowers[maxEquip] or 0
    local snap = {
        maxEquip = maxEquip,
        ownedTotal = #slotPowers,
        best = best,
        bestNonHuge = bestNonHugePw,
        weakest = weakest,
    }
    Runtime.Cache.TeamPowerSnapshot = snap
    Runtime.Cache.TeamPowerSnapshotAt = now
    Runtime.Stats.TeamPowerBest = best
    Runtime.Stats.TeamPowerWeakest = weakest
    return snap
end

local function EnsureBestPetsEquipped(force)
    if not Config.AutoEquipBestPets or not Modules.PetCmds then
        return
    end
    local now = os.clock()
    if not force and (now - (Runtime.Cache.LastEquipBestAt or 0)) < 0.6 then
        return
    end
    Runtime.Cache.LastEquipBestAt = now
    if Modules.PetCmds.IsAutoEquipEnabled and Modules.PetCmds.ToggleAutoEquip then
        local okA, enabled = pcall(Modules.PetCmds.IsAutoEquipEnabled)
        if okA and not enabled then
            pcall(Modules.PetCmds.ToggleAutoEquip)
        end
    end
    if Modules.PetCmds.EquipBest then
        pcall(Modules.PetCmds.EquipBest)
    end
end

local function IsEggOnMyIsland(egg, islandBox, pos)
    if not islandBox or not PT or not PT.OnIsland then
        return true
    end
    if pos and PT.OnIsland(islandBox.cf, islandBox.size, pos) then
        return true
    end
    if egg and egg._model and IsOnMyIsland(egg._model, islandBox) then
        return true
    end
    return false
end

local function ResolveTargetEgg(plot, buttons, preferHighestUnlocked)
    if not plot or not Modules.CustomEggsCmds or not Modules.CustomEggsCmds.All then
        return nil, nil, nil, nil
    end

    local part2 = Runtime.Helpers.IsPlotPart2Active(plot)
    local sig = tostring(plot:GetId())
        .. "|" .. tostring(Config.TargetEggName)
        .. "|" .. tostring(Config.FallbackHighestUnlockedEgg)
        .. "|" .. tostring(Runtime.Stats.ButtonsDone)
        .. "|" .. tostring(part2)
    if Runtime.Cache.TargetEggSig ~= sig then
        Runtime.Cache.TargetEggSig = sig
        table.clear(Runtime.Cache.TargetEggCache)
    end

    local modeKey = preferHighestUnlocked and "early" or "main"
    local cached = Runtime.Cache.TargetEggCache[modeKey]
    local now = os.clock()
    if cached then
        if cached.uid ~= nil and (now - cached.at) < 5.0 then
            return cached.uid, cached.name, cached.pos, cached.maxPerEgg
        elseif cached.uid == nil and (now - cached.at) < 0.75 then
            return nil, nil, nil, nil
        end
    end

    local ok, allEggs = pcall(Modules.CustomEggsCmds.All)
    if not ok or type(allEggs) ~= "table" then
        return nil, nil, nil, nil
    end

    local islandBox = GetIslandBox(plot)
    local ownedEggNames = {}
    local zoneEggNames = {}
    if PT and PT.ZONES then
        local maxZones = GetZoneCount(plot)
        for i = 1, math.min(#PT.ZONES, maxZones) do
            local z = PT.ZONES[i]
            if z and type(z.Egg) == "string" then
                zoneEggNames[z.Egg] = true
                local eggBtnId = z.Section .. "_Egg"
                if Modules.PumpkinButtonsUtil and Modules.PumpkinButtonsUtil.Owned(buttons, eggBtnId) then
                    ownedEggNames[z.Egg] = true
                end
            end
        end
    end

    local candidateNames = {}
    local seenNames = {}
    local function pushName(name)
        if type(name) == "string" and not seenNames[name] then
            seenNames[name] = true
            table.insert(candidateNames, name)
        end
    end

    if not preferHighestUnlocked then
        pushName(Config.TargetEggName)
    end
    if (preferHighestUnlocked or Config.FallbackHighestUnlockedEgg) and PT and PT.ZONES then
        local maxZones = GetZoneCount(plot)
        for i = math.min(#PT.ZONES, maxZones), 1, -1 do
            local z = PT.ZONES[i]
            if z and z.Egg and ownedEggNames[z.Egg] then
                pushName(z.Egg)
            end
        end
    end
    if preferHighestUnlocked then
        pushName(Config.TargetEggName)
    end

    for _, wantedName in ipairs(candidateNames) do
        local isOwnedZoneEgg = ownedEggNames[wantedName] == true
        local isUnownedZoneEgg = zoneEggNames[wantedName] == true and not isOwnedZoneEgg
        if not isUnownedZoneEgg then
            for uid, egg in pairs(allEggs) do
                if type(egg) == "table" and egg._id == wantedName and egg._destroyed ~= true then
                    -- Part 2 islands span >1000 studs so server toggles _hatchable=false when >~350 studs away;
                    -- trust owned zone egg buttons so StepHatch teleports back to the target egg instead of falling back to Zone 1-2.
                    local canHatch = isOwnedZoneEgg or (egg._hatchable == true)
                    if not canHatch and egg.IsHatchable then
                        local hOk, hRes = pcall(egg.IsHatchable, egg)
                        canHatch = hOk and hRes == true
                    end
                    if canHatch then
                        local pos = egg._position
                        if not pos and egg._model then
                            local okP, piv = pcall(egg._model.GetPivot, egg._model)
                            if okP and piv then
                                pos = piv.Position
                            end
                        end
                        if pos and IsEggOnMyIsland(egg, islandBox, pos) then
                            local maxPerEgg = tonumber(egg._maxEggCount)
                            if not maxPerEgg and egg.GetMaxEggCount then
                                local mOk, mRes = pcall(egg.GetMaxEggCount, egg)
                                maxPerEgg = mOk and tonumber(mRes) or nil
                            end
                            local resolvedUid = tostring(egg._uid or uid)
                            Runtime.Cache.TargetEggCache[modeKey] = {
                                uid = resolvedUid,
                                name = wantedName,
                                pos = pos,
                                maxPerEgg = maxPerEgg,
                                at = now,
                            }
                            return resolvedUid, wantedName, pos, maxPerEgg
                        end
                    end
                end
            end
        end
    end

    Runtime.Cache.TargetEggCache[modeKey] = { uid = nil, at = now }
    return nil, nil, nil, nil
end

function Runtime.Helpers.GetMaxHatchCount()
    if Modules.EggCmds and Modules.EggCmds.GetMaxHatch then
        local ok, m = pcall(Modules.EggCmds.GetMaxHatch)
        if ok and type(m) == "number" and m >= 1 then
            return math.floor(m)
        end
    end
    return 1
end

function Runtime.Helpers.GetEarlyHatchMaxCoins(eggCost, lowHatch, maxEquip)
    local eq = math.max(4, math.floor(tonumber(maxEquip) or 15))
    local maxCoins = math.max(0, tonumber(Config.EarlyHatchMaxCoinsPerEgg) or 35000000)
    local isPart2Egg = (type(eggCost) == "number" and eggCost >= 100000)
    if isPart2Egg then
        -- Part 2 Eggs 6-8 (128k..8.192M): allow enough eggs to craft a full Rainbow team (100 Normals / 10 Golds per Rainbow)
        local minP2Eggs = math.max(300, math.floor(tonumber(Config.EarlyHatchPart2RainbowMinEggs) or 1300))
        local p2EggBudget = lowHatch
            and math.clamp(math.max(minP2Eggs, eq * 110), minP2Eggs, 1800)
            or math.clamp(math.max(minP2Eggs, eq * 115), minP2Eggs, 3500)
        return math.max(maxCoins, eggCost * p2EggBudget)
    end
    if lowHatch and type(eggCost) == "number" and eggCost > 0 then
        local cfgLow = math.max(8, math.floor(tonumber(Config.EarlyHatchLowHatchMaxEggs) or 300))
        local lowCapEggs = math.clamp(math.max(cfgLow, eq * 16), cfgLow, 450)
        maxCoins = math.min(maxCoins, lowCapEggs * eggCost)
    end
    return maxCoins
end

EvaluateEarlyBootstrap = function(plot, buttons)
    if not Config.AutoHatch or not Config.AutoEarlyHatchForDamage or not plot then
        Runtime.Cache.ReserveEarlyEggCost = 0
        return false
    end
    local eggUid, eggName, eggPos, eggMax = ResolveTargetEgg(plot, buttons, true)
    if not eggUid or not eggPos then
        Runtime.Cache.ReserveEarlyEggCost = 0
        return false
    end

    local eggCost = GetEggPrice(eggName)
    local commonDmg = Runtime.Helpers.GetEggCommonEventDamage(eggName)
    if commonDmg <= 0 then
        commonDmg = GetEggCommonPower(eggName)
    end
    local snap = GetTeamPowerSnapshot(false)
    local goldReady = Config.AutoMakeGold ~= false and Runtime.Helpers.HasCraftMachineUnlocked("GoldMachine", plot, buttons)
    local rainbowReady = Config.AutoMakeRainbow ~= false and Runtime.Helpers.HasCraftMachineUnlocked("RainbowMachine", plot, buttons)
    local craftUpgradeEnabled = (Config.EarlyHatchUpgradeWithCraft ~= false) and (commonDmg > 0) and (goldReady or rainbowReady)

    local needsBasic = (snap.ownedTotal < snap.maxEquip)
        or (commonDmg > 0 and snap.weakest < (commonDmg * 0.99))

    if needsBasic then
        local cfgBasic = math.max(1, math.floor(tonumber(Config.EarlyHatchMaxPerEgg) or 8))
        local basicCap = math.max(cfgBasic, math.floor(tonumber(Config.EarlyHatchBasicMaxCap) or 25))
        local maxBasic = math.clamp(math.max(cfgBasic, snap.maxEquip), cfgBasic, basicCap)
        local hatchedHere = Runtime.Cache.EarlyHatchedByEgg[eggName] or 0
        if hatchedHere < maxBasic then
            Runtime.Cache.ReserveEarlyEggCost = (Config.EarlyHatchReserveCoins ~= false) and eggCost or 0
            return true, eggUid, eggName, eggPos, eggMax, eggCost, (maxBasic - hatchedHere)
        end
        if not craftUpgradeEnabled then
            Runtime.Cache.ReserveEarlyEggCost = 0
            return false
        end
        -- Gold/Rainbow craft upgrade mode is active: fall through to craft-upgrade budget instead of deadlocking at maxBasic
    end

    if not craftUpgradeEnabled then
        Runtime.Cache.ReserveEarlyEggCost = 0
        return false
    end

    -- Scale craft bootstrap targets to maxHatch & Part 2 Eggs (full Rainbow team on Part 2 Eggs 6-8 even on low-hatch accounts)
    local maxHatch = Runtime.Helpers.GetMaxHatchCount()
    local lowHatch = (maxHatch < 4)
    local isPart2Egg = (type(eggCost) == "number" and eggCost >= 100000)
    local uncommonDmg = Runtime.Helpers.GetEggUncommonEventDamage(eggName)
    local fullRainbowTarget = rainbowReady and (not lowHatch or isPart2Egg)
    local variantCap = fullRainbowTarget
        and math.min(4, tonumber(Config.EarlyHatchTargetVariantMult) or 4)
        or 2
    local targetWeakDmg = commonDmg * variantCap
    local bestMult = rainbowReady
        and (lowHatch and 4 or (tonumber(Config.EarlyHatchTargetBestMult) or 5.5))
        or variantCap
    local targetBestDmg = commonDmg * bestMult
    if uncommonDmg > commonDmg then
        if lowHatch then
            targetWeakDmg = math.max(targetWeakDmg, uncommonDmg * ((isPart2Egg and goldReady) and 2 or 1))
            targetBestDmg = math.max(targetBestDmg, uncommonDmg * (goldReady and 2 or 1))
        else
            targetWeakDmg = math.max(targetWeakDmg, uncommonDmg * (goldReady and 2 or 1))
            targetBestDmg = math.max(targetBestDmg, uncommonDmg * (rainbowReady and 4 or (goldReady and 2 or 1)))
        end
    end
    local needsUpgrade = needsBasic
        or (snap.weakest < (targetWeakDmg * 0.99))
        or ((goldReady or rainbowReady) and snap.bestNonHuge < (targetBestDmg * 0.99))
    if not needsUpgrade then
        Runtime.Cache.ReserveEarlyEggCost = 0
        return false
    end

    local maxCoins = Runtime.Helpers.GetEarlyHatchMaxCoins(eggCost, lowHatch, snap.maxEquip)
    local spentCoins = Runtime.Cache.EarlyCoinsSpentByEgg[eggName] or 0
    local budgetRem = maxCoins - spentCoins
    if budgetRem < eggCost then
        Runtime.Cache.ReserveEarlyEggCost = 0
        return false
    end

    local coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
    local minBalRatio = math.max(1, tonumber(Config.EarlyHatchMinBalanceRatio) or 20)
    if coins < (eggCost * minBalRatio) then
        Runtime.Cache.ReserveEarlyEggCost = 0
        return false
    end

    local minCritBtn = GetMinCriticalButtonPrice(buttons, plot)
    local maxShare = math.clamp(tonumber(Config.EarlyHatchMaxShareOfNextButton) or 0.25, 0.05, 0.95)
    -- Only pause near next critical button if remaining early-hatch budget meaningfully affects buying it (> 5% of button price)
    if minCritBtn and minCritBtn > 0 and coins >= (minCritBtn * (1 - maxShare)) and budgetRem > (minCritBtn * 0.05) then
        Runtime.Cache.ReserveEarlyEggCost = 0
        return false
    end

    Runtime.Cache.ReserveEarlyEggCost = (Config.EarlyHatchReserveCoins ~= false) and eggCost or 0
    local remainingCap = math.max(1, math.floor(budgetRem / eggCost))
    return true, eggUid, eggName, eggPos, eggMax, eggCost, remainingCap
end

local function ComputeEggOverlapPos(eggPos, maxDist)
    local targetPos = activeFarmTarget and activeFarmTarget.model and activeFarmTarget.model.Parent and activeFarmTarget.pos
    if not targetPos then
        local pool = Runtime.Cache.TapTargets
        if type(pool) == "table" and pool[1] and pool[1].pos then
            targetPos = pool[1].pos
        end
    end
    if targetPos then
        local dx = targetPos.X - eggPos.X
        local dz = targetPos.Z - eggPos.Z
        local hDist = math.sqrt(dx * dx + dz * dz)
        if hDist > 1 and hDist <= 120 then
            local stopDist = math.min(hDist, math.clamp((tonumber(maxDist) or 30) - 8, 10, 22))
            return Vector3.new(eggPos.X + (dx / hDist) * stopDist, targetPos.Y, eggPos.Z + (dz / hDist) * stopDist)
        end
    end
    return eggPos
end

local function StepHatch(plot, buttons, tycoonComplete)
    if not Config.AutoHatch or not plot or Runtime.Stats.FightingTurkeyBoss then
        Runtime.Stats.IsHatching = false
        Runtime.Cache.ActiveHatchEggPos = nil
        return
    end

    local isEarly = false
    local eggUid, eggName, eggPos, eggMax, eggCost, remainingCap

    if Config.RushButtonsFirst and not tycoonComplete then
        local needEarly
        needEarly, eggUid, eggName, eggPos, eggMax, eggCost, remainingCap = EvaluateEarlyBootstrap(plot, buttons)
        if not needEarly then
            Runtime.Stats.IsHatching = false
            Runtime.Cache.ActiveHatchEggPos = nil
            return
        end
        isEarly = true
    else
        Runtime.Cache.ReserveEarlyEggCost = 0
        eggUid, eggName, eggPos, eggMax = ResolveTargetEgg(plot, buttons, false)
        if not eggUid or not eggPos then
            Runtime.Stats.IsHatching = false
            Runtime.Cache.ActiveHatchEggPos = nil
            return
        end
        eggCost = GetEggPrice(eggName)
    end

    local maxHatch = Runtime.Helpers.GetMaxHatchCount()
    if type(eggMax) == "number" and eggMax >= 1 then
        maxHatch = math.min(maxHatch, eggMax)
    end
    if isEarly and type(remainingCap) == "number" then
        maxHatch = math.min(maxHatch, math.max(1, remainingCap))
    end

    local coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
    local batchMult = isEarly and 1 or (tonumber(Config.HatchMinBatchMultiplier) or 1)
    local minReq = eggCost * batchMult
    if coins < minReq then
        Runtime.Stats.IsHatching = false
        Runtime.Cache.ActiveHatchEggPos = nil
        return
    end

    local batch = math.clamp(math.floor(coins / eggCost), 1, maxHatch)
    if batch < 1 then
        Runtime.Stats.IsHatching = false
        Runtime.Cache.ActiveHatchEggPos = nil
        return
    end

    if not Config.AutoHatch or IsMoveLocked() or (Runtime.Cache.HatchYieldUntil or 0) > os.clock() then
        Runtime.Stats.IsHatching = false
        Runtime.Cache.ActiveHatchEggPos = nil
        return
    end

    Runtime.Cache.ActiveHatchEggPos = eggPos
    Runtime.Stats.IsHatching = true
    Runtime.Stats.Phase = (isEarly and "Early Hatch " or "Hatching ") .. eggName
    SuppressEggAnimation()

    Runtime.Cache.HatchInFlight = true
    local moveMaxDist = tonumber(Config.HatchMoveMaxDist) or 30
    local _, hrp = GetCharacter()
    if hrp and (HorizontalDist(hrp.Position, eggPos) > moveMaxDist or math.abs(hrp.Position.Y - eggPos.Y) > 18) then
        local dest = ComputeEggOverlapPos(eggPos, moveMaxDist)
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
        end)
        MoveNear(dest, 4)
        local waitUntil = os.clock() + 1.10
        task.wait(0.15) -- Allow physics position replication before CustomEggs_Hatch range check
        local eggObj = Modules.CustomEggsCmds and Modules.CustomEggsCmds.Get and Modules.CustomEggsCmds.Get(eggUid)
        while IsRunning() and eggObj and eggObj._hatchable ~= true and os.clock() < waitUntil do
            task.wait(0.04)
        end
        if not IsRunning() or not Config.AutoHatch or Runtime.Stats.FightingTurkeyBoss or IsMoveLocked() or (Runtime.Cache.HatchYieldUntil or 0) > os.clock() then
            Runtime.Cache.HatchInFlight = false
            Runtime.Stats.IsHatching = false
            Runtime.Cache.ActiveHatchEggPos = nil
            return
        end
        coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
        batch = math.clamp(math.floor(coins / eggCost), 1, maxHatch)
        if coins < eggCost or batch < 1 then
            Runtime.Cache.HatchInFlight = false
            Runtime.Stats.IsHatching = false
            Runtime.Cache.ActiveHatchEggPos = nil
            return
        end
    end

    local ok, res, errMsg = pcall(Modules.Network.Invoke, "CustomEggs_Hatch", eggUid, batch)
    Runtime.Cache.HatchInFlight = false
    if ok and res == true then
        local spentNow = batch * eggCost
        Runtime.Helpers.RecordCoinsSpent(spentNow)
        Runtime.Stats.EggsHatched = Runtime.Stats.EggsHatched + batch
        if isEarly then
            Runtime.Stats.EarlyEggsHatched = Runtime.Stats.EarlyEggsHatched + batch
            Runtime.Cache.EarlyHatchedByEgg[eggName] = (Runtime.Cache.EarlyHatchedByEgg[eggName] or 0) + batch
            Runtime.Cache.EarlyCoinsSpentByEgg[eggName] = (Runtime.Cache.EarlyCoinsSpentByEgg[eggName] or 0) + spentNow
            local now = os.clock()
            local hatchedCnt = Runtime.Cache.EarlyHatchedByEgg[eggName]
            local prevSnap = Runtime.Cache.TeamPowerSnapshot
            local prevMaxEquip = (prevSnap and prevSnap.maxEquip) or 15
            local isFinalBatch = (type(remainingCap) == "number" and remainingCap <= batch)
            local shouldRescan = (hatchedCnt <= prevMaxEquip)
                or isFinalBatch
                or ((now - (Runtime.Cache.LastEarlySnapAt or 0)) >= 1.5)
            local snap = prevSnap
            if shouldRescan then
                Runtime.Cache.LastEarlySnapAt = now
                local prevBest = prevSnap and prevSnap.best or 0
                local prevWeak = prevSnap and prevSnap.weakest or 0
                Runtime.Cache.TeamPowerSnapshotAt = 0
                snap = GetTeamPowerSnapshot(true)
                if snap.ownedTotal < snap.maxEquip or snap.best > prevBest or snap.weakest > prevWeak or (now - (Runtime.Cache.LastEquipBestAt or 0)) >= 4.0 then
                    EnsureBestPetsEquipped(true)
                end
            end
            if hatchedCnt <= 8 or isFinalBatch or (hatchedCnt % 50 == 0) or (now - (Runtime.Cache.LastEarlyHatchLogAt or 0)) >= 15 then
                Runtime.Cache.LastEarlyHatchLogAt = now
                local spentM = (Runtime.Cache.EarlyCoinsSpentByEgg[eggName] or 0) / 1e6
                local capCoins = Runtime.Helpers.GetEarlyHatchMaxCoins(eggCost, maxHatch < 4, snap and snap.maxEquip or prevMaxEquip)
                Log("INFO", "Early-hatched [%s]: %d eggs (%.2fM/%.1fM Coins, team best=%s weakest=%s)",
                    eggName,
                    hatchedCnt,
                    spentM,
                    capCoins / 1e6,
                    tostring(snap and (snap.bestNonHuge or snap.best) or 0),
                    tostring(snap and snap.weakest or 0))
            end
        end
    elseif ok and res == false and errMsg == "Failed to commit!" then
        Runtime.Stats.IsHatching = false
        Runtime.Cache.ActiveHatchEggPos = nil
        table.clear(Runtime.Cache.TargetEggCache)
        task.wait(0.35)
    elseif not ok or res == false then
        Runtime.Stats.IsHatching = false
        if type(errMsg) == "string" and string.find(errMsg, "far away", 1, true) then
            Runtime.Cache.ActiveHatchEggPos = nil
            table.clear(Runtime.Cache.TargetEggCache)
        end
        Log("DEBUG", "Hatch failed [%s x%d]: %s", tostring(eggName), batch, tostring(errMsg or res))
    end
end

-- ============================================================================
-- 11B. PET CRAFTING (GOLD & RAINBOW MACHINE)
-- ============================================================================
local CRAFT_SPECS = {
    {
        kind = "Gold",
        configKey = "AutoMakeGold",
        machineName = "GoldMachine",
        invokeName = "GoldMachine_Activate",
        perkName = "GoldReduction",
        statKey = "GoldCrafted",
        requireNormal = true,
        requireGolden = false,
        canCraftFnName = "CanGoldMachine",
    },
    {
        kind = "Rainbow",
        configKey = "AutoMakeRainbow",
        machineName = "RainbowMachine",
        invokeName = "RainbowMachine_Activate",
        perkName = "RainbowReduction",
        statKey = "RainbowCrafted",
        requireNormal = false,
        requireGolden = true,
        canCraftFnName = "CanRainbowMachine",
    },
}

local function SafeMethodBool(obj, methodName)
    if not obj or type(obj[methodName]) ~= "function" then
        return nil
    end
    local ok, res = pcall(obj[methodName], obj)
    if ok then
        return res == true
    end
    return nil
end

local function HasAncestorNamed(inst, targetName)
    local cur = inst
    while cur do
        if cur.Name == targetName then
            return true
        end
        cur = cur.Parent
    end
    return false
end

local function AddEggPetsToSet(set, eggName)
    local eggsDir = Modules.Directory and Modules.Directory.Eggs
    if type(eggsDir) ~= "table" or type(eggName) ~= "string" or eggName == "" then
        return 0
    end
    local eggDir = SafeDirLookup(eggsDir, eggName)
    if type(eggDir) ~= "table" or type(eggDir.pets) ~= "table" then
        return 0
    end
    local added = 0
    for _, entry in ipairs(eggDir.pets) do
        local petId = type(entry) == "table" and entry[1] or entry
        if type(petId) == "string" and petId ~= "" and not set[petId] then
            set[petId] = true
            added = added + 1
        end
    end
    return added
end

--- Build and lazily cache the PumpkinTycoon event pet ID whitelist from Directory.Eggs, Buttons, and Zones.
local function GetEventCraftPetSet()
    if type(Runtime.Cache.CraftEventPetSet) == "table" and next(Runtime.Cache.CraftEventPetSet) ~= nil then
        return Runtime.Cache.CraftEventPetSet
    end

    local set = {}
    local eggsDir = Modules.Directory and Modules.Directory.Eggs
    if type(eggsDir) == "table" then
        pcall(function()
            for _, eggDir in pairs(eggsDir) do
                if type(eggDir) == "table" and type(eggDir.pets) == "table" then
                    local scriptRef = rawget(eggDir, "_script") or eggDir._script
                    if scriptRef and HasAncestorNamed(scriptRef, INSTANCE_ID) then
                        for _, entry in ipairs(eggDir.pets) do
                            local petId = type(entry) == "table" and entry[1] or entry
                            if type(petId) == "string" and petId ~= "" then
                                set[petId] = true
                            end
                        end
                    end
                end
            end
        end)
    end

    local buttonsList = Modules.ButtonsTypes and Modules.ButtonsTypes.BUTTONS
    if type(buttonsList) == "table" then
        for _, btn in ipairs(buttonsList) do
            if type(btn) == "table" and type(btn.Egg) == "string" then
                AddEggPetsToSet(set, btn.Egg)
            end
        end
    end

    local zones = (Modules.PumpkinTycoon and Modules.PumpkinTycoon.ZONES) or (PT and PT.ZONES)
    if type(zones) == "table" then
        for _, zone in ipairs(zones) do
            if type(zone) == "table" and type(zone.Egg) == "string" then
                AddEggPetsToSet(set, zone.Egg)
            end
        end
    end

    local roster = (Modules.PumpkinTycoon and Modules.PumpkinTycoon.ROSTER) or (PT and PT.ROSTER)
    if type(roster) == "table" then
        for _, r in ipairs(roster) do
            local petId = type(r) == "table" and r.Pet or nil
            if type(petId) == "string" and petId ~= "" then
                set[petId] = true
            end
        end
    end
    local rosterP2 = (Modules.PumpkinTycoon and Modules.PumpkinTycoon.ROSTER_RUNG_P2) or (PT and PT.ROSTER_RUNG_P2)
    if type(rosterP2) == "table" then
        for petId in pairs(rosterP2) do
            if type(petId) == "string" and petId ~= "" then
                set[petId] = true
            end
        end
    end

    if next(set) ~= nil then
        Runtime.Cache.CraftEventPetSet = set
    end
    return set
end

--- Compute required pets per single craft after Mastery GoldReduction / RainbowReduction perks.
local function GetCraftCost(spec)
    local cost = 10
    local mastery = Modules.MasteryCmds
    if mastery and type(mastery.HasPerk) == "function" and type(mastery.GetPerkPower) == "function" then
        local okHas, hasPerk = pcall(mastery.HasPerk, "Pets", spec.perkName)
        if okHas and hasPerk then
            local okPow, power = pcall(mastery.GetPerkPower, "Pets", spec.perkName)
            if okPow and type(power) == "number" then
                cost = math.max(1, 10 - math.floor(power))
            end
        end
    end
    return cost
end

local function IsCraftMachineUnlocked(spec, plot, buttons)
    return Runtime.Helpers.HasCraftMachineUnlocked(spec.machineName, plot, buttons)
end

local function CollectDaycareUIDs(cmdModule, daycareUids)
    if not cmdModule or type(cmdModule.GetActive) ~= "function" then
        return
    end
    local ok, active = pcall(cmdModule.GetActive)
    if not ok or type(active) ~= "table" then
        return
    end
    for slotKey, entry in pairs(active) do
        if type(slotKey) == "string" and slotKey ~= "" then
            daycareUids[slotKey] = true
        end
        if type(entry) == "table" then
            if type(entry.uid) == "string" and entry.uid ~= "" then
                daycareUids[entry.uid] = true
            end
            if type(entry._uid) == "string" and entry._uid ~= "" then
                daycareUids[entry._uid] = true
            end
            if type(entry.Pet) == "table" then
                local petUid = entry.Pet.uid or entry.Pet._uid or entry.Pet._id or entry.Pet.UID
                if type(petUid) == "string" and petUid ~= "" then
                    daycareUids[petUid] = true
                end
            end
        end
    end
end

local function GetProtectedCraftingSets()
    local daycareUids = {}
    CollectDaycareUIDs(Modules.DaycareCmds, daycareUids)
    CollectDaycareUIDs(Modules.ExclusiveDaycareCmds, daycareUids)

    local equippedCounts = {}
    if Config.CraftProtectEquipped ~= false and Modules.PetCmds and type(Modules.PetCmds.GetEquipped) == "function" then
        local okEq, equipped = pcall(Modules.PetCmds.GetEquipped)
        if okEq and type(equipped) == "table" then
            for _, eq in pairs(equipped) do
                local stackUid = type(eq) == "table" and (eq.uid or eq._uid) or (type(eq) == "string" and eq or nil)
                if type(stackUid) == "string" and stackUid ~= "" then
                    equippedCounts[stackUid] = (equippedCounts[stackUid] or 0) + 1
                end
            end
        end
    end

    local maxEquip = 4
    if Modules.PetCmds and type(Modules.PetCmds.GetMaxEquipped) == "function" then
        local okMax, m = pcall(Modules.PetCmds.GetMaxEquipped)
        if okMax and type(m) == "number" and m >= 1 then
            maxEquip = math.floor(m)
        end
    end

    return {
        daycare = daycareUids,
        equippedCounts = equippedCounts,
        maxEquip = maxEquip,
    }
end

local function FetchPetInventory()
    if not Modules.Save or type(Modules.Save.Get) ~= "function" then
        return nil
    end
    local okSave, saveData = pcall(Modules.Save.Get)
    local invPets = okSave and type(saveData) == "table" and saveData.Inventory and saveData.Inventory.Pet
    return type(invPets) == "table" and invPets or nil
end

local function CollectInventoryCraftState(invPets)
    local totalOwnedPets = 0
    for _, data in pairs(invPets) do
        if type(data) == "table" and type(data.id) == "string" then
            totalOwnedPets = totalOwnedPets + math.max(1, math.floor(tonumber(data._am) or 1))
        end
    end
    return totalOwnedPets, GetProtectedCraftingSets()
end

local function IsPetStackEligibleForCraft(uid, data, spec, protected, eventPetSet, petsDir, cost)
    if type(data) ~= "table" or type(data.id) ~= "string" then
        return false
    end
    if Config.CraftEventPetsOnly ~= false and (not eventPetSet or not eventPetSet[data.id]) then
        return false
    end
    if protected.daycare[uid] then
        return false
    end

    -- Pre-filter cheap raw Save fields and available amount before PetItem:Get(uid) / Directory lookup
    if spec.requireNormal then
        if data.pt ~= nil and data.pt ~= 0 then
            return false
        end
    elseif spec.requireGolden then
        if data.pt ~= 1 then
            return false
        end
    else
        return false
    end

    if Config.CraftProtectLocked ~= false then
        if (data._lk == true) or (data.l == true) or (data.lock == true) then
            return false
        end
    end

    if Config.CraftProtectShiny ~= false and data.sh == true then
        return false
    end

    local rawAmount = math.max(1, math.floor(tonumber(data._am) or 1))
    local available = rawAmount - (protected.equippedCounts[uid] or 0)
    if available < (cost or 1) then
        return false
    end

    local pd = SafeDirLookup(petsDir, data.id)
    if pd then
        if pd.huge == true or pd.titanic == true or pd.gargantuan == true
            or (type(pd.exclusiveLevel) == "number" and pd.exclusiveLevel > 0)
        then
            return false
        end
        if spec.requireNormal and (pd.preventGolden == true or pd.preventGoldMachine == true) then
            return false
        end
        if spec.requireGolden and (pd.preventRainbow == true or pd.preventRainbowMachine == true) then
            return false
        end
    elseif string.sub(data.id, 1, 5) == "Huge "
        or string.sub(data.id, 1, 8) == "Titanic "
        or string.sub(data.id, 1, 11) == "Gargantuan "
    then
        return false
    end

    local inst = ResolvePetItem(uid)
    if inst then
        if spec.requireNormal and SafeMethodBool(inst, "IsNormal") == false then
            return false
        elseif spec.requireGolden and SafeMethodBool(inst, "IsGolden") == false then
            return false
        end
        if Config.CraftProtectLocked ~= false and SafeMethodBool(inst, "IsLocked") == true then
            return false
        end
        if Config.CraftProtectShiny ~= false and SafeMethodBool(inst, "IsShiny") == true then
            return false
        end
        if SafeMethodBool(inst, spec.canCraftFnName) == false then
            return false
        end
        if SafeMethodBool(inst, "IsHuge") == true
            or SafeMethodBool(inst, "IsTitanic") == true
            or SafeMethodBool(inst, "IsGargantuan") == true
        then
            return false
        end
        if type(inst.GetExclusiveLevel) == "function" then
            local okEx, exLvl = pcall(inst.GetExclusiveLevel, inst)
            if okEx and type(exLvl) == "number" and exLvl > 0 then
                return false
            end
        end
    end

    return true, inst, pd, available
end

local function EstimateCandidateCraftPower(data, inst, pd, spec)
    local evDmg = select(1, Runtime.Helpers.GetPetEventDamage(data, inst, pd))
    if type(evDmg) == "number" and evDmg > 0 then
        return evDmg
    end
    if inst and type(inst.CalculatePower) == "function" then
        local okP, val = pcall(inst.CalculatePower, inst)
        if okP and type(val) == "number" and val > 0 then
            return val
        end
    end
    if pd then
        local mult = spec.requireGolden and 3 or 1
        return ((type(pd.cachedPower) == "table" and tonumber(pd.cachedPower[1])) or tonumber(pd.power) or 0) * mult
    end
    return 0
end

--- Build deterministic craft batches for one machine spec (strongest pets first) while honoring team protections.
local function BuildCraftPlans(spec, cost, invPets, protected, eventPetSet, totalOwnedPets, minBatchOverride)
    local plans = {}
    if type(invPets) ~= "table" or cost < 1 then
        return plans
    end

    local petsDir = Modules.Directory and Modules.Directory.Pets
    local candidates = {}
    for uid, data in pairs(invPets) do
        local eligible, inst, pd, available = IsPetStackEligibleForCraft(uid, data, spec, protected, eventPetSet, petsDir, cost)
        if eligible then
            table.insert(candidates, {
                uid = uid,
                petId = data.id,
                available = available,
                power = EstimateCandidateCraftPower(data, inst, pd, spec),
            })
        end
    end

    table.sort(candidates, function(a, b)
        if a.power ~= b.power then
            return a.power > b.power
        end
        if a.available ~= b.available then
            return a.available > b.available
        end
        if a.petId ~= b.petId then
            return a.petId < b.petId
        end
        return tostring(a.uid) < tostring(b.uid)
    end)

    local minBatch = math.max(1, math.floor(tonumber(minBatchOverride or Config.CraftMinBatch) or 1))
    local reserveTeam = Config.CraftReserveMinTeamSlots ~= false
    local spareSlots = reserveTeam and math.max(0, totalOwnedPets - (protected.maxEquip or 4)) or math.huge

    for _, cand in ipairs(candidates) do
        local crafts = math.floor(cand.available / cost)
        if reserveTeam and cost > 1 then
            local maxBySlots = math.floor(spareSlots / (cost - 1))
            crafts = math.min(crafts, maxBySlots)
        end
        if crafts >= minBatch then
            if reserveTeam and cost > 1 then
                spareSlots = spareSlots - (crafts * (cost - 1))
            end
            table.insert(plans, {
                uid = cand.uid,
                petId = cand.petId,
                crafts = crafts,
                consume = crafts * cost,
            })
        end
    end

    return plans
end

local function ExecuteCraftPlans(plot, spec, plans, cost)
    local totalCrafted = 0
    local totalShiny = 0
    local padVisited = false
    local hadFailure = false
    local consumedByUid = {}

    local padOk = WithMachinePad(plot, spec.machineName, 80, function()
        padVisited = true
        Runtime.Stats.Phase = "Crafting " .. spec.kind
        CloseMachineTab(spec.machineName)

        local maxPerInvoke = math.max(1, math.floor(tonumber(Config.CraftMaxBatchPerInvoke) or 25))
        for _, plan in ipairs(plans) do
            local remaining = plan.crafts
            while IsRunning() and remaining > 0 do
                ExtendMachineSession(4.0)
                local batch = math.min(remaining, maxPerInvoke)
                local callOk, invokeOk, errOrMsg, shinyCount = pcall(Modules.Network.Invoke, spec.invokeName, plan.uid, batch)
                if callOk and invokeOk == true then
                    Runtime.Cache.CraftFailUntil[spec.kind] = 0
                    local shinyMade = type(shinyCount) == "number" and math.max(0, math.floor(shinyCount)) or 0
                    totalCrafted = totalCrafted + batch
                    totalShiny = totalShiny + shinyMade
                    consumedByUid[plan.uid] = (consumedByUid[plan.uid] or 0) + (batch * cost)
                    Runtime.Stats[spec.statKey] = (Runtime.Stats[spec.statKey] or 0) + batch
                    Runtime.Stats.ShinyCrafted = (Runtime.Stats.ShinyCrafted or 0) + shinyMade
                    remaining = remaining - batch
                    Log("INFO", "Crafted %dx %s [%s]%s",
                        batch,
                        spec.kind,
                        tostring(plan.petId),
                        shinyMade > 0 and string.format(" (%dx Shiny)", shinyMade) or ""
                    )
                    if remaining > 0 then
                        task.wait(0.08)
                    end
                else
                    hadFailure = true
                    Runtime.Cache.CraftFailUntil[spec.kind] = os.clock() + (tonumber(Config.CraftFailCooldownSec) or 10)
                    Log("DEBUG", "Craft %s failed [%s x%d]: %s",
                        spec.kind, tostring(plan.petId), batch, tostring(errOrMsg or invokeOk))
                    break
                end
            end
            if hadFailure or not IsRunning() then
                break
            end
        end

        CloseMachineTab(spec.machineName)
    end, { standOnPad = true, closeModal = true })

    if not padVisited or not padOk then
        hadFailure = true
        Runtime.Cache.CraftFailUntil[spec.kind] = os.clock() + (tonumber(Config.CraftFailCooldownSec) or 10)
        Log("DEBUG", "Craft %s machine pad unavailable [%s]", spec.kind, tostring(spec.machineName))
    end

    return totalCrafted, totalShiny, hadFailure, consumedByUid
end

local function CountGoldPets(invPets)
    local total = 0
    if type(invPets) ~= "table" then
        return 0
    end
    for _, entry in pairs(invPets) do
        if type(entry) == "table" and entry.pt == 1 then
            total = total + math.max(1, math.floor(tonumber(entry._am) or 1))
        end
    end
    return total
end

--- Poll Save.Inventory.Pet briefly after Gold crafting until source deductions & crafted output replicate.
local function WaitForCraftReplication(prevGoldCount, beforeAmounts, consumedByUid, crafted, timeoutSec)
    if crafted <= 0 then
        local curInv = FetchPetInventory()
        if not curInv then
            return nil
        end
        local curTotal, curProtected = CollectInventoryCraftState(curInv)
        return curInv, curTotal, curProtected
    end

    local deadline = os.clock() + (tonumber(timeoutSec) or 0.90)
    local lastDeductedInv, lastDeductedTotal, lastDeductedProtected

    while IsRunning() do
        ExtendMachineSession(4.0)
        local curInv = FetchPetInventory()
        if curInv then
            local allDeducted = true
            for uid, consumed in pairs(consumedByUid) do
                if consumed > 0 then
                    local prevAm = beforeAmounts[uid] or 0
                    local curEntry = curInv[uid]
                    local curAm = (type(curEntry) == "table") and math.max(1, math.floor(tonumber(curEntry._am) or 1)) or 0
                    if curAm > math.max(0, prevAm - consumed) then
                        allDeducted = false
                        break
                    end
                end
            end

            if CountGoldPets(curInv) >= (prevGoldCount + crafted) then
                local curTotal, curProtected = CollectInventoryCraftState(curInv)
                return curInv, curTotal, curProtected
            end
            if allDeducted then
                local curTotal, curProtected = CollectInventoryCraftState(curInv)
                lastDeductedInv = curInv
                lastDeductedTotal = curTotal
                lastDeductedProtected = curProtected
            end
        end

        if os.clock() >= deadline then
            break
        end
        task.wait(0.05)
    end

    if lastDeductedInv then
        return lastDeductedInv, lastDeductedTotal, lastDeductedProtected
    end
    return nil
end

local function RefreshCraftedTeamPower()
    Runtime.Cache.TeamPowerSnapshotAt = 0
    GetTeamPowerSnapshot(true)
    EnsureBestPetsEquipped(true)
    task.delay(0.15, function()
        if IsRunning() then
            Runtime.Cache.TeamPowerSnapshotAt = 0
            GetTeamPowerSnapshot(true)
            EnsureBestPetsEquipped(true)
        end
    end)
end

local function IsSpecReadyToCheck(spec, plot, buttons, now)
    if not Config[spec.configKey] then
        return false
    end
    if now < ((Runtime.Cache.CraftFailUntil and Runtime.Cache.CraftFailUntil[spec.kind]) or 0) then
        return false
    end
    return IsCraftMachineUnlocked(spec, plot, buttons)
end

--- Periodically scan inventory for Gold & Rainbow crafts, yielding politely to AutoHatch before chaining trips.
local function StepCraftPets(plot, buttons)
    if not plot or not Modules.Network then
        return
    end
    if not Config.AutoMakeGold and not Config.AutoMakeRainbow then
        return
    end

    local now = os.clock()
    local checkInterval = math.max(0.2, tonumber(Config.CraftCheckIntervalSec) or 1.0)
    if (now - (Runtime.Cache.LastCraftCheckAt or 0)) < checkInterval then
        return
    end
    Runtime.Cache.LastCraftCheckAt = now

    local anyEnabled = false
    for _, spec in ipairs(CRAFT_SPECS) do
        if IsSpecReadyToCheck(spec, plot, buttons, now) then
            anyEnabled = true
            break
        end
    end
    if not anyEnabled then
        Runtime.Cache.PendingCraftReadySince = 0
        return
    end

    local eventPetSet = nil
    if Config.CraftEventPetsOnly ~= false then
        eventPetSet = GetEventCraftPetSet()
        if not eventPetSet or next(eventPetSet) == nil then
            return
        end
    end

    local invPets = FetchPetInventory()
    if not invPets then
        return
    end
    local totalOwnedPets, protected = CollectInventoryCraftState(invPets)

    local isHatchingNow = (Runtime.Stats.IsHatching == true) or (Runtime.Cache.HatchInFlight == true)
    local isPostCompleteAfk = (Runtime.Stats.TycoonComplete == true) and isHatchingNow
    local triggerMinBatch = isPostCompleteAfk
        and math.max(1, math.floor(tonumber(Config.CraftPostCompleteMinBatch) or 5))
        or math.max(1, math.floor(tonumber(Config.CraftMinBatch) or 1))

    local hasPendingWork = false
    for _, spec in ipairs(CRAFT_SPECS) do
        if IsSpecReadyToCheck(spec, plot, buttons, now) then
            local plans = BuildCraftPlans(spec, GetCraftCost(spec), invPets, protected, eventPetSet, totalOwnedPets, triggerMinBatch)
            if #plans > 0 then
                hasPendingWork = true
                break
            end
        end
    end
    if not hasPendingWork then
        Runtime.Cache.PendingCraftReadySince = 0
        return
    end

    if (Runtime.Cache.PendingCraftReadySince or 0) == 0 then
        Runtime.Cache.PendingCraftReadySince = now
    end

    if isHatchingNow then
        local yieldSec = isPostCompleteAfk
            and math.max(0, tonumber(Config.CraftHatchYieldIntervalSec) or 30.0)
            or math.max(0, tonumber(Config.CraftEarlyHatchYieldIntervalSec) or 8.0)
        local waitSinceReady = now - (Runtime.Cache.PendingCraftReadySince or now)
        local waitSinceTrip = now - (Runtime.Cache.LastCraftTripAt or 0)
        if waitSinceReady < yieldSec or waitSinceTrip < yieldSec then
            return
        end
    end

    Runtime.Cache.PendingCraftReadySince = 0
    Runtime.Cache.LastCraftTripAt = os.clock()

    local totalCraftedAny = 0
    WithMachineSession(function()
        -- Re-read inventory after BeginMachineSession yields so in-flight hatches/equips settle before planning.
        invPets = FetchPetInventory()
        if not invPets then
            return
        end
        totalOwnedPets, protected = CollectInventoryCraftState(invPets)

        local prevCrafted = 0
        local prevGoldCount = CountGoldPets(invPets)
        local prevBeforeAmounts = nil
        local prevConsumedByUid = nil

        for idx, spec in ipairs(CRAFT_SPECS) do
            if not IsRunning() then
                break
            end

            local stepNow = os.clock()
            if IsSpecReadyToCheck(spec, plot, buttons, stepNow) then
                local cost = GetCraftCost(spec)
                if idx > 1 and prevCrafted > 0 then
                    if (prevGoldCount + prevCrafted) < cost then
                        prevCrafted = 0
                        break
                    end
                    local updatedInv, newTotal, newProtected = WaitForCraftReplication(
                        prevGoldCount,
                        prevBeforeAmounts,
                        prevConsumedByUid,
                        prevCrafted,
                        0.90
                    )
                    if not updatedInv then
                        Log("DEBUG", "Skipping %s pass: waiting for prior %s save replication timed out",
                            spec.kind, CRAFT_SPECS[idx - 1].kind)
                        break
                    end
                    invPets = updatedInv
                    totalOwnedPets = newTotal
                    protected = newProtected
                end

                local plans = BuildCraftPlans(spec, cost, invPets, protected, eventPetSet, totalOwnedPets)
                if #plans > 0 then
                    local beforeAmounts = {}
                    for _, plan in ipairs(plans) do
                        local entry = invPets[plan.uid]
                        beforeAmounts[plan.uid] = (type(entry) == "table")
                            and math.max(1, math.floor(tonumber(entry._am) or 1))
                            or 0
                    end

                    prevGoldCount = CountGoldPets(invPets)
                    local crafted, _, _, consumedByUid = ExecuteCraftPlans(plot, spec, plans, cost)
                    totalCraftedAny = totalCraftedAny + crafted
                    prevCrafted = crafted
                    prevBeforeAmounts = beforeAmounts
                    prevConsumedByUid = consumedByUid
                else
                    prevCrafted = 0
                end
            end
        end
    end)

    if totalCraftedAny > 0 then
        RefreshCraftedTeamPower()
    end
end

-- ============================================================================
-- 12. OPTIONAL EVENT PASS CLAIM LOOP
-- ============================================================================
local function StepEventPass()
    if not Config.AutoEventPass or not Modules.Network or not Modules.EventPassUtil or not Modules.EventPassTypes then
        return
    end
    local now = os.clock()
    if now - (Runtime.Cache.LastPassCheckAt or 0) < 15 then
        return
    end
    Runtime.Cache.LastPassCheckAt = now

    local passId = Modules.EventPassUtil.Current and Modules.EventPassUtil.Current() or ""
    if passId == "" then
        return
    end
    local ok, state = pcall(Modules.Network.Invoke, Modules.EventPassTypes.NET.Get, passId)
    if not ok or type(state) ~= "table" then
        return
    end
    local passCfg = Modules.EventPassUtil.Get and Modules.EventPassUtil.Get(passId)
    if not passCfg or not Modules.EventPassUtil.WeekSet then
        return
    end
    local weekSet = Modules.EventPassUtil.WeekSet(passCfg, state.Week or 1)
    if not weekSet or type(weekSet.Tiers) ~= "table" then
        return
    end

    if state.Buying == false then
        return
    end
    local stars = tonumber(state.Stars) or 0
    local spent = tonumber(state.Spent) or 0
    local owned = type(state.Owned) == "table" and state.Owned or {}
    local tierUnlock = type(state.TierUnlock) == "table" and state.TierUnlock or {}

    for tierIdx, cards in ipairs(weekSet.Tiers) do
        local reqSpent = tierUnlock[tierIdx]
        if reqSpent ~= nil and spent >= reqSpent then
            for _, card in ipairs(cards) do
                local comingSoon = Modules.EventPassUtil.ComingSoon and Modules.EventPassUtil.ComingSoon(card)
                if not comingSoon and card.Key and not owned[card.Key] and type(card.Cost) == "number" and stars >= card.Cost then
                    local bOk, bRes = pcall(Modules.Network.Invoke, Modules.EventPassTypes.NET.Buy, passId, card.Key)
                    if bOk and bRes == true then
                        stars = stars - card.Cost
                        spent = spent + card.Cost
                        owned[card.Key] = true
                        Log("INFO", "Claimed Event Pass reward [%s]", tostring(card.Key))
                        task.wait(0.08)
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- 12A. PART 2 PET NET STORE, WILD HUNT & SIGHTING CATCH
-- ============================================================================
function Runtime.Helpers.GetNetCount(netId)
    if type(netId) ~= "string" or netId == "" then
        return 0
    end
    if Modules.MiscItem then
        local ok, cnt = pcall(function()
            return Modules.MiscItem(netId):CountExact()
        end)
        if ok and type(cnt) == "number" then
            return math.max(0, math.floor(cnt))
        end
    end
    local okSave, saveData = false, nil
    if Modules.Save and Modules.Save.Get then
        okSave, saveData = pcall(Modules.Save.Get)
    end
    local invMisc = okSave and type(saveData) == "table" and saveData.Inventory and saveData.Inventory.Misc
    if type(invMisc) ~= "table" then
        return 0
    end
    local total = 0
    for _, item in pairs(invMisc) do
        if type(item) == "table" and item.id == netId then
            total = total + math.max(1, math.floor(tonumber(item._am) or 1))
        end
    end
    return total
end

function Runtime.Helpers.PickHuntNet(isHugeOrSighting)
    local order = Modules.WildTypes and Modules.WildTypes.NET_ORDER
    local netNormal = (type(order) == "table" and order[1]) or "Pet Net"
    local netUltra = (type(order) == "table" and order[2]) or "Ultra Pet Net"
    local normalCnt = Runtime.Helpers.GetNetCount(netNormal)
    local ultraCnt = Runtime.Helpers.GetNetCount(netUltra)
    local ultraOnHuge = (Config.HuntUltraOnHuge ~= false)

    if isHugeOrSighting then
        if ultraOnHuge then
            if ultraCnt > 0 then
                return netUltra, normalCnt, ultraCnt
            end
            if Config.HuntUseNormalNetOnHuge ~= false and normalCnt > 0 then
                return netNormal, normalCnt, ultraCnt
            end
            return nil, normalCnt, ultraCnt
        else
            if normalCnt > 0 then
                return netNormal, normalCnt, ultraCnt
            end
            if ultraCnt > 0 then
                return netUltra, normalCnt, ultraCnt
            end
            return nil, normalCnt, ultraCnt
        end
    end

    if normalCnt > 0 then
        return netNormal, normalCnt, ultraCnt
    end
    if not ultraOnHuge and ultraCnt > 0 then
        return netUltra, normalCnt, ultraCnt
    end
    return nil, normalCnt, ultraCnt
end

function Runtime.Helpers.GetWildSpeciesInfo(zone, petId)
    if type(petId) ~= "string" then
        return { huge = false, tier = 0 }
    end
    local spMap = Runtime.Cache.WildSpeciesMap
    if spMap == nil then
        spMap = {}
        local wt = Modules.WildTypes
        if wt and type(wt.Species) == "function" then
            for z = 1, 8 do
                local ok, list = pcall(wt.Species, z)
                if ok and type(list) == "table" then
                    local zMap = {}
                    for _, entry in ipairs(list) do
                        if type(entry) == "table" and type(entry.PetId) == "string" then
                            zMap[entry.PetId] = {
                                huge = entry.Huge == true,
                                tier = entry.Huge and (wt.HUGE_TIER or 4) or (tonumber(entry.Tier) or 0),
                            }
                        end
                    end
                    spMap[z] = zMap
                end
            end
        end
        Runtime.Cache.WildSpeciesMap = spMap
    end

    local zEntry = type(zone) == "number" and spMap[zone] and spMap[zone][petId] or nil
    if zEntry then
        return zEntry
    end
    for _, zMap in pairs(spMap) do
        if zMap[petId] then
            return zMap[petId]
        end
    end

    local petsDir = Modules.Directory and Modules.Directory.Pets
    local pd = type(petsDir) == "table" and rawget(petsDir, petId) or nil
    local isHuge = (pd and (pd.huge == true or pd.titanic == true or pd.gargantuan == true))
        or string.sub(petId, 1, 5) == "Huge "
        or string.sub(petId, 1, 8) == "Titanic "
        or string.sub(petId, 1, 11) == "Gargantuan "
    return {
        huge = isHuge == true,
        tier = isHuge and 4 or 0,
    }
end

function Runtime.Helpers.EnsureSightingHook()
    if Runtime.Cache.SightingHookBound then
        return
    end
    if not Modules.Network or type(Modules.Network.Fired) ~= "function" then
        return
    end
    local remoteName = (Modules.PumpkinSightingUtil and Modules.PumpkinSightingUtil.REMOTE) or "PumpkinTycoon: PV_Seen"
    local ok, sig = pcall(Modules.Network.Fired, remoteName)
    if not ok or not sig then
        return
    end
    Runtime.Cache.SightingHookBound = true
    BindConn(sig, function(payload)
        if not IsRunning() or type(payload) ~= "table" or type(payload.id) ~= "string" then
            return
        end
        if payload.closed == true then
            local cur = Runtime.Cache.ActiveSighting
            if cur and cur.id == payload.id then
                Runtime.Cache.ActiveSighting = nil
            end
            return
        end
        if payload.thrown ~= true and type(payload.entry) == "table" then
            Runtime.Cache.ActiveSighting = {
                id = payload.id,
                slot = tostring(payload.slot or "HugeTurkey"),
                entry = payload.entry,
                expiresAt = tonumber(payload.expiresAt) or (workspace:GetServerTimeNow() + 180),
                spot = type(payload.spot) == "table" and Vector3.new(payload.spot[1] or 0, payload.spot[2] or 0, payload.spot[3] or 0) or nil,
                thrown = false,
            }
            Log("INFO", "Sighting detected [%s] (id=%s, slot=%s)", tostring(payload.entry.P), payload.id, tostring(payload.slot or "HugeTurkey"))
        end
    end)
end

function Runtime.Helpers.GetNetStoreShelf(plot, forceFetch)
    local storeFeat = PT_Cmds and type(PT_Cmds.Feature) == "function" and select(2, pcall(PT_Cmds.Feature, "Store")) or nil
    local shelf = nil
    if not forceFetch and storeFeat and type(storeFeat.Shelf) == "function" then
        local okS, resS = pcall(storeFeat.Shelf)
        if okS and type(resS) == "table" and resS.seed ~= nil and type(resS.offers) == "table" and #resS.offers > 0 then
            shelf = resS
        end
    end

    local needFetch = forceFetch or (shelf == nil)
    if not needFetch and storeFeat and type(storeFeat.RefreshIn) == "function" then
        local okR, rem = pcall(storeFeat.RefreshIn)
        if okR and type(rem) == "number" and rem <= 2 then
            needFetch = true
        end
    end

    local now = os.clock()
    if needFetch and plot and (now - (Runtime.Cache.LastNetStoreShelfFetchAt or 0)) >= 5.0 then
        Runtime.Cache.LastNetStoreShelfFetchAt = now
        local okCall, okRes, _, data = pcall(plot.Invoke, plot, NET.NetShelf)
        if okCall and okRes and type(data) == "table" and type(data.Offers) == "table" then
            local parsed = {}
            for slotKey, offer in pairs(data.Offers) do
                local itemData = type(offer) == "table" and offer.ItemData and offer.ItemData.data
                local priceData = type(offer) == "table" and offer.PriceData and offer.PriceData.data
                table.insert(parsed, {
                    slot = tonumber(slotKey) or 0,
                    item = itemData and itemData.id or "",
                    price = priceData and tonumber(priceData._am) or 0,
                    left = tonumber(offer.Stock) or 0,
                })
            end
            table.sort(parsed, function(a, b)
                return a.slot < b.slot
            end)
            shelf = { seed = data.Seed, offers = parsed }
            Runtime.Cache.NetStoreShelfCache = shelf
        end
    end

    return shelf or Runtime.Cache.NetStoreShelfCache, storeFeat
end

function Runtime.Helpers.StepNetStore(plot, buttons, tycoonComplete)
    if Config.AutoBuyNetStore == false or not plot then
        return
    end
    if not Runtime.Helpers.IsPlotPart2Active(plot) then
        return
    end
    local storeUtil = Modules.PumpkinStoreUtil
    if storeUtil and type(storeUtil.Enabled) == "function" then
        local okE, enabled = pcall(storeUtil.Enabled)
        if okE and not enabled then
            return
        end
    end
    local storeBtn = (storeUtil and storeUtil.BUTTON) or "PetNetStore"
    if not Modules.PumpkinButtonsUtil or not Modules.PumpkinButtonsUtil.Owned(buttons, storeBtn) then
        return
    end

    local now = os.clock()
    local interval = math.max(1.5, tonumber(Config.NetStoreCheckIntervalSec) or 4.0)
    if (now - (Runtime.Cache.LastNetStoreStepAt or 0)) < interval then
        return
    end
    Runtime.Cache.LastNetStoreStepAt = now

    if (now - (Runtime.Cache.LastNetStoreFailAt or 0)) < 10.0 then
        return
    end

    local shelf, storeFeat = Runtime.Helpers.GetNetStoreShelf(plot, false)

    -- Keep server built-in AutoBuyNets off so Rush budget rules are enforced accurately
    if Config.KeepServerAutoNetsOff ~= false and (now - (Runtime.Cache.LastNetStoreAutoSyncAt or 0)) >= 15.0 then
        local serverAutoOn = false
        if storeFeat and type(storeFeat.AutoOn) == "function" then
            local okA, resA = pcall(storeFeat.AutoOn)
            serverAutoOn = okA and resA == true
        elseif storeUtil and type(storeUtil.AutoOn) == "function" then
            local autoVar = storeUtil.AUTO_VAR or "NetStoreAuto"
            local pumpAutoVar = storeUtil.PUMPKIN_AUTO_VAR or "AutoBuy"
            local okA, resA = pcall(storeUtil.AutoOn, Runtime.Helpers.GetPlotSave(plot, autoVar), Runtime.Helpers.GetPlotSave(plot, pumpAutoVar))
            serverAutoOn = okA and resA == true
        end
        if serverAutoOn then
            Runtime.Cache.LastNetStoreAutoSyncAt = now
            local okOff, resOff = pcall(plot.Invoke, plot, NET.SetAutoNets, false)
            if okOff and resOff then
                Runtime.Helpers.InvalidatePlotSave(plot, (storeUtil and storeUtil.AUTO_VAR) or "NetStoreAuto")
                Log("INFO", "Disabled server AutoBuyNets to enforce script budget policy.")
            end
        end
    end

    if type(shelf) ~= "table" or shelf.seed == nil or type(shelf.offers) ~= "table" or #shelf.offers == 0 then
        return
    end

    local ultraId = (storeUtil and storeUtil.ULTRA_NET) or "Ultra Pet Net"
    local normalId = (storeUtil and storeUtil.NET) or "Pet Net"
    local merchantId = (storeUtil and storeUtil.MERCHANT) or "PetNetStore"

    local discountMult = 1
    if Modules.MasteryCmds and type(Modules.MasteryCmds.GetPerkPower) == "function" then
        local okP, perk = pcall(Modules.MasteryCmds.GetPerkPower, "Economy", "CheaperMerchants")
        if okP and type(perk) == "number" and perk > 0 and perk < 100 then
            discountMult = 1 - (perk / 100)
        end
    end

    local offers = {}
    for _, o in ipairs(shelf.offers) do
        if type(o) == "table" and (tonumber(o.left) or 0) > 0 and (tonumber(o.slot) or 0) >= 1 and (tonumber(o.price) or 0) > 0 then
            table.insert(offers, o)
        end
    end
    if #offers == 0 then
        return
    end

    table.sort(offers, function(a, b)
        local aUltra = (a.item == ultraId)
        local bUltra = (b.item == ultraId)
        if aUltra ~= bUltra then
            return aUltra
        end
        if a.price ~= b.price then
            return a.price < b.price
        end
        return a.slot < b.slot
    end)

    local coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
    local rushMode = (Config.RushButtonsFirst == true and not tycoonComplete)
    local rushShare = math.clamp(tonumber(Config.NetStoreMaxRushCoinShare) or 0.05, 0, 1)
    local minSpare = math.max(0, tonumber(Config.NetStoreMinSpareCoins) or 0)
    local plan = {}
    local simCoins = coins
    local totalPlanned = 0

    for _, o in ipairs(offers) do
        if totalPlanned >= 12 then
            break
        end
        local isUltra = (o.item == ultraId)
        local isNormal = (o.item == normalId)
        local allowedItem = (isUltra and Config.NetStoreBuyUltra ~= false)
            or (isNormal and Config.NetStoreBuyNormal ~= false)
            or (not isUltra and not isNormal)

        if allowedItem then
            local cost = math.max(1, math.ceil(o.price * discountMult))
            local stockLeft = math.floor(tonumber(o.left) or 0)
            local buyQty = 0
            while stockLeft > 0 and totalPlanned < 12 do
                local canAfford = false
                if isUltra then
                    canAfford = (simCoins >= cost)
                elseif rushMode then
                    local spendable = math.max(0, simCoins - (Runtime.Cache.ReserveEarlyEggCost or 0))
                    canAfford = (rushShare > 0) and (spendable >= cost) and (cost <= (simCoins * rushShare))
                else
                    canAfford = (simCoins >= (cost + minSpare))
                end
                if not canAfford then
                    break
                end
                simCoins = math.max(0, simCoins - cost)
                stockLeft = stockLeft - 1
                buyQty = buyQty + 1
                totalPlanned = totalPlanned + 1
            end
            if buyQty > 0 then
                table.insert(plan, { offer = o, cost = cost, qty = buyQty })
            end
        end
    end

    if #plan == 0 then
        return
    end

    WithMachinePad(plot, merchantId, 20, function()
        for _, req in ipairs(plan) do
            if not IsRunning() then
                break
            end
            for _ = 1, req.qty do
                if not IsRunning() then
                    break
                end
                local okBuy, resBuy, errBuy = pcall(Modules.Network.Invoke, "Merchant_RequestPurchase", merchantId, req.offer.slot, false, shelf.seed)
                if okBuy and resBuy == true then
                    req.offer.left = math.max(0, (tonumber(req.offer.left) or 1) - 1)
                    Runtime.Helpers.RecordCoinsSpent(req.cost)
                    Runtime.Stats.NetsBought = (Runtime.Stats.NetsBought or 0) + 1
                    Log("INFO", "Bought [%s] (slot %d) for %s Coins", tostring(req.offer.item), req.offer.slot, tostring(req.cost))
                    task.wait(0.08)
                else
                    Runtime.Cache.LastNetStoreFailAt = os.clock()
                    Runtime.Cache.LastNetStoreShelfFetchAt = 0
                    Log("DEBUG", "Net Store buy failed [%s slot %d]: %s", tostring(req.offer.item), req.offer.slot, tostring(errBuy or resBuy))
                    return
                end
            end
        end
        if Modules.TabController and Modules.TabController.IsOpen and Modules.TabController.IsOpen("Merchant") then
            pcall(Modules.TabController.CloseTab)
        end
    end, { closeModal = true })
end

function Runtime.Helpers.StepSightingCatch(plot)
    if Config.AutoCatchSighting == false or not plot then
        return false
    end
    local s = Runtime.Cache.ActiveSighting
    if type(s) ~= "table" or s.thrown == true then
        return false
    end
    if not Runtime.Helpers.IsPlotPart2Active(plot) then
        return false
    end
    local sightUtil = Modules.PumpkinSightingUtil
    if sightUtil and type(sightUtil.Enabled) == "function" then
        local okE, enabled = pcall(sightUtil.Enabled)
        if okE and not enabled then
            return false
        end
    end

    local nowServer = workspace:GetServerTimeNow()
    if s.expiresAt and nowServer >= s.expiresAt then
        Runtime.Cache.ActiveSighting = nil
        return false
    end

    if Modules.ChaseTypes and type(Modules.ChaseTypes.SoldOutAttribute) == "function" then
        local attrName = Modules.ChaseTypes.SoldOutAttribute(s.slot)
        if attrName and Workspace:GetAttribute(attrName) == true then
            s.thrown = true
            Runtime.Cache.ActiveSighting = nil
            Log("INFO", "Sighting [%s] is sold out; skipping.", tostring(s.entry and s.entry.P or s.slot))
            return false
        end
    end

    local throwCd = (Modules.PumpkinWildUtil and Modules.PumpkinWildUtil.ThrowSeconds and Modules.PumpkinWildUtil.ThrowSeconds()) or 3
    if (nowServer - (Runtime.Cache.LastWildThrowAt or 0)) < (throwCd + 0.1) then
        return false
    end

    local netName = Runtime.Helpers.PickHuntNet(true)
    if not netName then
        return false
    end

    local ok, res, reason, payload = false, false, nil, nil
    local needMove = false
    if typeof(s.spot) == "Vector3" then
        local _, hrp = GetCharacter()
        needMove = (hrp ~= nil and (hrp.Position - s.spot).Magnitude > 40)
    end
    if needMove then
        WithMachineSession(function()
            MoveNear(s.spot, 8)
            task.wait(0.35)
            ok, res, reason, payload = pcall(plot.Invoke, plot, NET.CatchSighting, s.id, netName)
        end)
    else
        ok, res, reason, payload = pcall(plot.Invoke, plot, NET.CatchSighting, s.id, netName)
    end
    if ok and res and type(payload) == "table" then
        Runtime.Cache.LastWildThrowAt = workspace:GetServerTimeNow()
        Runtime.Stats.WildThrows = (Runtime.Stats.WildThrows or 0) + 1
        s.thrown = true
        Runtime.Cache.ActiveSighting = nil
        if payload.outcome == "soldout" then
            Log("INFO", "Sighting [%s] sold out on catch attempt.", tostring(s.entry and s.entry.P or s.slot))
            return true
        end
        if payload.caught == true then
            if type(payload.uid) == "string" and Modules.Network and Modules.Network.Fire then
                pcall(Modules.Network.Fire, "SM_Unmask", { payload.uid })
            end
            Runtime.Stats.SightingsCaught = (Runtime.Stats.SightingsCaught or 0) + 1
            Runtime.Stats.WildCaught = (Runtime.Stats.WildCaught or 0) + 1
            Runtime.Stats.WildHugesCaught = (Runtime.Stats.WildHugesCaught or 0) + 1
            Log("INFO", "Caught Sighting [%s] with [%s]!", tostring(payload.pet or (s.entry and s.entry.P) or s.slot), netName)
        else
            Log("INFO", "Missed Sighting [%s] with [%s].", tostring(payload.pet or (s.entry and s.entry.P) or s.slot), netName)
        end
        return true
    end

    Runtime.Cache.LastWildFailAt = os.clock()
    Log("DEBUG", "Sighting catch failed [%s net=%s]: %s", tostring(s.id), netName, tostring(reason or res))
    return false
end

function Runtime.Helpers.StepWildHunt(plot, buttons)
    if Config.AutoHuntWild == false or not plot then
        return
    end
    if not Runtime.Helpers.IsPlotPart2Active(plot) then
        return
    end
    local wildUtil = Modules.PumpkinWildUtil
    if not wildUtil or (type(wildUtil.Enabled) == "function" and not wildUtil.Enabled()) then
        return
    end

    local now = os.clock()
    if (now - (Runtime.Cache.LastWildStepAt or 0)) < 0.4 then
        return
    end
    Runtime.Cache.LastWildStepAt = now

    if (now - (Runtime.Cache.LastWildFailAt or 0)) < 3.0 then
        return
    end

    -- Turn off built-in server Auto Hunt (80-stud / 6s) so it never collides with full-island custom hunt
    if Config.DisableServerAutoHunt ~= false and (now - (Runtime.Cache.LastHuntAutoSyncAt or 0)) >= 15.0 then
        local huntSave = Runtime.Helpers.GetPlotSave(plot, VAR.Hunt)
        if type(huntSave) == "table" and huntSave.On == true then
            Runtime.Cache.LastHuntAutoSyncAt = now
            local cleanRules = {
                On = false,
                Min = tonumber(huntSave.Min) or 4,
                Variant = huntSave.Variant == true,
                UltraOnHuge = huntSave.UltraOnHuge ~= false,
            }
            local okOff, resOff = pcall(plot.Invoke, plot, NET.SetHunt, cleanRules)
            if okOff and resOff then
                Runtime.Helpers.InvalidatePlotSave(plot, VAR.Hunt)
                Log("INFO", "Disabled built-in server Auto Hunt in favor of full-island script hunt.")
            end
        end
    end

    -- Ensure active Sighting check runs independently of AutoHuntWild via RunManagerTick
    local nowServer = workspace:GetServerTimeNow()
    local throwCd = (type(wildUtil.ThrowSeconds) == "function" and wildUtil.ThrowSeconds()) or 3
    if (nowServer - (Runtime.Cache.LastWildThrowAt or 0)) < (throwCd + 0.1) then
        return
    end

    local rawWild = Runtime.Helpers.GetPlotSave(plot, VAR.Wild)
    local entries = type(wildUtil.Entries) == "function" and wildUtil.Entries(rawWild) or nil
    if type(entries) ~= "table" or next(entries) == nil then
        return
    end

    local perZone = type(wildUtil.PerZone) == "function" and wildUtil.PerZone() or nil
    local wildFeat = PT_Cmds and type(PT_Cmds.Feature) == "function" and select(2, pcall(PT_Cmds.Feature, "Wild")) or nil
    local slotCooldowns = Runtime.Cache.WildSlotCooldown

    local minTier = math.clamp(math.floor(tonumber(Config.HuntMinTier) or 4), 0, 4)
    local variantsOnly = (Config.HuntVariantsOnly == true)
    local alwaysCatchHuges = (Config.HuntAlwaysCatchHuges ~= false)
    local minChance = math.max(0, tonumber(Config.HuntMinCatchChance) or 0)

    local best = nil
    for slotKey, entry in pairs(entries) do
        local slotNum = tonumber(slotKey)
        if slotNum and type(entry) == "table" and type(entry.P) == "string" then
            local zone, idx = wildUtil.Split(slotNum)
            if zone and entry.Z == zone and (entry.I == nil or entry.I == idx) and wildUtil.Served(slotNum, perZone) then
                local zoneMeta = PT and PT.ZONES and PT.ZONES[zone]
                local zoneOwned = zoneMeta and Modules.PumpkinButtonsUtil
                    and Modules.PumpkinButtonsUtil.Owned(buttons, zoneMeta.Section .. "_Zone")
                if zoneOwned then
                    local entryKey = string.format("%d|%s|%s|%s|%s|%.4f",
                        slotNum,
                        entry.P,
                        entry.G and "1" or "0",
                        entry.R and "1" or "0",
                        entry.S and "1" or "0",
                        tonumber(entry.C) or 0)
                    local cdUntil = slotCooldowns[entryKey]
                    local busy = false
                    if wildFeat and type(wildFeat.Physical) == "function" then
                        local okP, phys = pcall(wildFeat.Physical, slotNum)
                        if okP and type(phys) == "table" and (phys.Catching == true or phys.AttemptingCatch == true) then
                            busy = true
                        end
                    end

                    if not busy and (not cdUntil or now >= cdUntil) then
                        local spInfo = Runtime.Helpers.GetWildSpeciesInfo(zone, entry.P)
                        local isHuge = spInfo.huge == true
                        local tier = tonumber(spInfo.tier) or 0
                        local isVariant = (entry.G == true or entry.R == true or entry.S == true)

                        local eligible = false
                        if isHuge then
                            eligible = alwaysCatchHuges or (not variantsOnly or isVariant)
                        elseif minTier < 4 and tier >= minTier then
                            eligible = (not variantsOnly) or isVariant
                        end

                        if eligible then
                            local netName = Runtime.Helpers.PickHuntNet(isHuge)
                            if netName then
                                local chance = (type(wildUtil.PlayerChance) == "function" and wildUtil.PlayerChance(entry, netName, LocalPlayer))
                                    or (tonumber(entry.C) or 0)
                                if chance >= minChance then
                                    local varRank = (entry.S and 4 or 0) + (entry.R and 2 or (entry.G and 1 or 0))
                                    local better = false
                                    if not best then
                                        better = true
                                    elseif isHuge ~= best.isHuge then
                                        better = isHuge
                                    elseif tier ~= best.tier then
                                        better = tier > best.tier
                                    elseif varRank ~= best.varRank then
                                        better = varRank > best.varRank
                                    elseif chance ~= best.chance then
                                        better = chance > best.chance
                                    end
                                    if better then
                                        best = {
                                            slot = slotNum,
                                            zone = zone,
                                            entry = entry,
                                            entryKey = entryKey,
                                            isHuge = isHuge,
                                            tier = tier,
                                            varRank = varRank,
                                            netName = netName,
                                            chance = chance,
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if not best then
        return
    end

    -- Server checks proximity to the wild pet's WildArea_<zone> before accepting RU_Ensnare
    local catchPos = nil
    if wildFeat then
        if type(wildFeat.Physical) == "function" then
            local okP, phys = pcall(wildFeat.Physical, best.slot)
            if okP and type(phys) == "table" then
                if phys.SpawnArea and phys.SpawnArea:IsA("BasePart") then
                    catchPos = phys.SpawnArea.Position + Vector3.new(0, 3, 0)
                elseif typeof(phys.At) == "Vector3" then
                    catchPos = phys.At + Vector3.new(0, 3, 0)
                end
            end
        end
        if not catchPos and type(wildFeat.Areas) == "function" then
            local okA, areaList = pcall(wildFeat.Areas, best.zone)
            if okA and type(areaList) == "table" and areaList[1] and areaList[1]:IsA("BasePart") then
                catchPos = areaList[1].Position + Vector3.new(0, 3, 0)
            end
        end
    end

    local ok, res, reason, payload = false, false, nil, nil
    local needMove = false
    if typeof(catchPos) == "Vector3" then
        local _, hrp = GetCharacter()
        needMove = (hrp ~= nil and HorizontalDist(hrp.Position, catchPos) > 35)
    end
    if needMove then
        WithMachineSession(function()
            local _, hrpNow = GetCharacter()
            if hrpNow then
                pcall(function()
                    hrpNow.AssemblyLinearVelocity = Vector3.zero
                end)
                hrpNow.CFrame = CFrame.new(catchPos)
                Runtime.Cache.LastTeleportAt = os.clock()
            end
            task.wait(0.35)
            ok, res, reason, payload = pcall(plot.Invoke, plot, NET.CatchWild, best.slot, best.netName)
        end)
    else
        ok, res, reason, payload = pcall(plot.Invoke, plot, NET.CatchWild, best.slot, best.netName)
    end
    if ok and res and type(payload) == "table" then
        Runtime.Cache.LastWildThrowAt = workspace:GetServerTimeNow()
        Runtime.Stats.WildThrows = (Runtime.Stats.WildThrows or 0) + 1
        Runtime.Helpers.InvalidatePlotSave(plot, VAR.Wild)
        for kCd, expAt in pairs(slotCooldowns) do
            if now >= expAt then
                slotCooldowns[kCd] = nil
            end
        end

        local varPrefix = (best.entry.S and "Shiny " or "")
            .. (best.entry.R and "Rainbow " or (best.entry.G and "Golden " or ""))
        if payload.outcome == "soldout" then
            slotCooldowns[best.entryKey] = now + 30.0
            Log("INFO", "Wild Huge sold out: [%s%s] (slot %d, Z%d)", varPrefix, best.entry.P, best.slot, best.zone)
        elseif payload.caught == true then
            slotCooldowns[best.entryKey] = now + 4.0
            if type(payload.uid) == "string" and Modules.Network and Modules.Network.Fire then
                pcall(Modules.Network.Fire, "SM_Unmask", { payload.uid })
            end
            Runtime.Stats.WildCaught = (Runtime.Stats.WildCaught or 0) + 1
            if best.isHuge then
                Runtime.Stats.WildHugesCaught = (Runtime.Stats.WildHugesCaught or 0) + 1
            end
            Log("INFO", "Caught Wild [%s%s] (slot %d, Z%d, net=%s, chance=%.1f%%)",
                varPrefix, best.entry.P, best.slot, best.zone, best.netName, (best.chance or 0) * 100)
        else
            slotCooldowns[best.entryKey] = now + 4.0
            Log("INFO", "Missed Wild [%s%s] (slot %d, Z%d, net=%s, chance=%.1f%%)",
                varPrefix, best.entry.P, best.slot, best.zone, best.netName, (best.chance or 0) * 100)
        end

        if wildFeat and type(wildFeat.Respawn) == "function" then
            pcall(wildFeat.Respawn, best.slot)
        end
        return
    end

    Runtime.Cache.LastWildFailAt = os.clock()
    Log("DEBUG", "Wild catch failed [%s slot %d net=%s]: %s", tostring(best.entry.P), best.slot, best.netName, tostring(reason or res))
end

-- ============================================================================
-- 11C. SERVER-WIDE TURKEY BOSS ENGINE (PART 2 TURKEY ARENA)
-- ============================================================================
function Runtime.Helpers.GetTurkeySharedModel()
    local things = Workspace:FindFirstChild("__THINGS")
    local instances = things and things:FindFirstChild("Instances")
    local instFolder = instances and instances:FindFirstChild(INSTANCE_ID)
    if not instFolder then
        return nil
    end
    local sharedName = (Modules.PumpkinIslandCmds and Modules.PumpkinIslandCmds.SHARED_NAME) or "PumpkinTycoonShared"
    return instFolder:FindFirstChild(sharedName)
end

function Runtime.Helpers.GetTurkeyReach()
    local util = Modules.PumpkinTurkeyUtil
    if util and type(util.Dial) == "function" then
        local ok, r = pcall(util.Dial, "PumpkinTycoon_TurkeyReach")
        if ok and type(r) == "number" and r >= 20 then
            return r
        end
    end
    return 150
end

function Runtime.Helpers.OwnsTurkeyCannon(plot, buttons)
    local tCmds = Modules.PumpkinTurkeyCmds
    if tCmds and type(tCmds.OwnsCannon) == "function" then
        local ok, res = pcall(tCmds.OwnsCannon)
        if ok and type(res) == "boolean" then
            return res
        end
    end
    if not plot then
        return false
    end
    if Runtime.Helpers.GetPlotSave(plot, VAR.CannonEver) == true then
        return true
    end
    local reb = tonumber(Runtime.Helpers.GetPlotSave(plot, VAR.Rebirths)) or 0
    if reb >= 1 then
        return true
    end
    local btns = buttons or Runtime.Cache.Buttons or Runtime.Helpers.GetPlotSave(plot, VAR.Buttons)
    if PT and type(PT.HasCannonButton) == "function" and btns then
        local ok, has = pcall(PT.HasCannonButton, btns)
        if ok and has == true then
            return true
        end
    end
    return false
end

function Runtime.Helpers.FindTurkeyBossBreakable()
    if not Modules.BreakableFrontend or not Modules.BreakableFrontend.AllByInstanceAndClass then
        return nil, nil, nil
    end
    local ok, chests = pcall(Modules.BreakableFrontend.AllByInstanceAndClass, "Chest")
    if not ok or type(chests) ~= "table" then
        return nil, nil, nil
    end
    for uid, data in pairs(chests) do
        local attrs = data and data.clientAttributes
        local model = data and data.model
        if type(attrs) == "table" and attrs.PumpkinTurkey == true and model and model.Parent then
            return tostring(uid), data, model
        end
    end
    return nil, nil, nil
end

function Runtime.Helpers.GetTurkeyArenaStandPos(shared, bossModel)
    local center = nil
    if bossModel and bossModel.Parent then
        local okP, cf = pcall(bossModel.GetPivot, bossModel)
        if okP and typeof(cf) == "CFrame" then
            center = cf.Position
        end
    end
    if not center and shared then
        local arena = shared:FindFirstChild("TurkeyArena", true)
        local spawnPart = arena and arena:FindFirstChild("TurkeySpawn", true)
        if spawnPart and spawnPart:IsA("BasePart") then
            center = spawnPart.Position
        end
    end
    if not center then
        center = Vector3.new(7930, 1998.3, 8000)
    end

    local offset = math.clamp(tonumber(Config.TurkeyBossStandOffset) or 18, 12, 40)
    local probe = Vector3.new(center.X + offset, center.Y, center.Z)
    local groundY = center.Y
    if shared then
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Include
        rp.FilterDescendantsInstances = { shared }
        rp.RespectCanCollide = true
        local hit = Workspace:Raycast(Vector3.new(probe.X, center.Y + 50, probe.Z), Vector3.new(0, -150, 0), rp)
        if hit and hit.Position then
            groundY = hit.Position.Y
        end
    end
    return Vector3.new(probe.X, groundY + 3.2, probe.Z), center
end

function Runtime.Helpers.GetTurkeyBossState(plot, buttons)
    if Config.AutoTurkeyBoss == false or not plot or not IsInEventInstance() then
        return nil
    end
    if not Runtime.Helpers.IsPlotPart2Active(plot) then
        return nil
    end

    local util = Modules.PumpkinTurkeyUtil
    if util and type(util.Enabled) == "function" then
        local okE, en = pcall(util.Enabled)
        if okE and en == false then
            return nil
        end
    end

    local ownsCannon = Runtime.Helpers.OwnsTurkeyCannon(plot, buttons)
    if Config.TurkeyBossRequireCannon == true and not ownsCannon then
        return nil
    end

    local shared = Runtime.Helpers.GetTurkeySharedModel()
    local attrMap = (util and util.ATTR) or {}
    local aliveAttr = attrMap.Alive or "TurkeyAlive"
    local endsAttr = attrMap.EndsAt or "TurkeyEndsAt"
    local hpAttr = attrMap.Health or "TurkeyHealth"
    local maxHpAttr = attrMap.MaxHealth or "TurkeyMaxHealth"
    local shareAttr = (util and util.SHARE_ATTR) or "PumpkinTurkeyShare"

    local alive = shared ~= nil and shared:GetAttribute(aliveAttr) == true
    local endsAt = shared and tonumber(shared:GetAttribute(endsAttr)) or 0
    local health = shared and tonumber(shared:GetAttribute(hpAttr)) or nil
    local maxHealth = shared and tonumber(shared:GetAttribute(maxHpAttr)) or nil

    local uid, data, model = Runtime.Helpers.FindTurkeyBossBreakable()
    local nowServer = workspace:GetServerTimeNow()
    local isLive = (model ~= nil) or (alive and (endsAt <= 0 or nowServer < (endsAt + 2)))
    if not isLive then
        return nil
    end

    local windowKey = (endsAt > 0) and endsAt or 1
    if Runtime.Cache.TurkeyBossSkippedEndsAt == windowKey then
        return nil
    end

    local myShare = tonumber(LocalPlayer and LocalPlayer:GetAttribute(shareAttr)) or 0
    local minShareStop = tonumber(Config.TurkeyBossMinShareStop) or 0
    if minShareStop > 0 and myShare >= minShareStop then
        Runtime.Cache.TurkeyBossSkippedEndsAt = windowKey
        Log("INFO", "Turkey Boss share reached %.2f%% (>= %.2f%%); returning to island.", myShare * 100, minShareStop * 100)
        return nil
    end

    local noDmgTimeout = tonumber(Config.TurkeyBossNoDamageTimeoutSec) or 25
    local engagedAt = tonumber(Runtime.Cache.TurkeyBossEngagedAt) or 0
    if noDmgTimeout > 0 and not ownsCannon and model ~= nil and engagedAt > 0 and myShare <= 0 then
        if (os.clock() - engagedAt) >= noDmgTimeout then
            Runtime.Cache.TurkeyBossSkippedEndsAt = windowKey
            Log("WARN", "Turkey Boss recorded 0%% share without Zone8_Cannon after %.0fs; skipping this spawn.", noDmgTimeout)
            return nil
        end
    end

    if health == nil and type(data) == "table" and type(data.health) == "number" then
        health = data.health
    end
    if maxHealth == nil and type(data) == "table" and type(data.maxHealth) == "number" then
        maxHealth = data.maxHealth
    end

    local standPos, centerPos = Runtime.Helpers.GetTurkeyArenaStandPos(shared, model)
    return {
        shared = shared,
        uid = uid,
        data = data,
        model = model,
        endsAt = endsAt,
        windowKey = windowKey,
        health = health or 0,
        maxHealth = maxHealth or 0,
        share = myShare,
        ownsCannon = ownsCannon,
        standPos = standPos,
        centerPos = centerPos,
    }
end

function Runtime.Helpers.ReturnFromTurkeyArena(plot)
    local prevShare = tonumber(Runtime.Stats.TurkeyBossShare) or 0
    local prevEndsAt = tonumber(Runtime.Cache.TurkeyBossActiveEndsAt) or 0
    local prevHp = tonumber(Runtime.Cache.TurkeyBossLastHealth)
    local nowServer = workspace:GetServerTimeNow()
    local contribMin = 0.01
    if Modules.PumpkinTurkeyUtil and type(Modules.PumpkinTurkeyUtil.Dial) == "function" then
        local okC, val = pcall(Modules.PumpkinTurkeyUtil.Dial, "PumpkinTycoon_TurkeyContribMin")
        if okC and type(val) == "number" and val > 0 then
            contribMin = val
        end
    end

    local prevWindowKey = (prevEndsAt > 0) and prevEndsAt or 1
    local skipped = (Runtime.Cache.TurkeyBossSkippedEndsAt == prevWindowKey)
    local killed = (not skipped) and ((prevHp ~= nil and prevHp <= 0) or (prevEndsAt > 0 and nowServer < (prevEndsAt - 5)))
    if killed and prevShare >= contribMin then
        Runtime.Stats.TurkeyBossKills = (Runtime.Stats.TurkeyBossKills or 0) + 1
    end

    Runtime.Stats.FightingTurkeyBoss = false
    Runtime.Stats.TurkeyBossShare = 0
    Runtime.Stats.TurkeyBossHealth = 0
    Runtime.Stats.TurkeyBossMaxHealth = 0
    Runtime.Cache.TurkeyBossActiveEndsAt = 0
    Runtime.Cache.TurkeyBossEngagedAt = 0
    Runtime.Cache.TurkeyBossLastHealth = nil
    activeFarmTarget = nil
    Runtime.Cache.TapTargets = nil
    Runtime.Stats.ActiveTargetUid = nil

    Log("INFO", "Turkey Boss session ended (killed=%s, share=%.2f%%); returning to home island.", tostring(killed), prevShare * 100)

    local retPos = Runtime.Cache.TurkeyBossReturnPos
    Runtime.Cache.TurkeyBossReturnPos = nil
    if not IsMoveLocked() then
        local _, hrp = GetCharacter()
        if hrp and typeof(retPos) == "Vector3" then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
            end)
            hrp.CFrame = CFrame.new(retPos + Vector3.new(0, 2.5, 0))
            Runtime.Cache.LastTeleportAt = os.clock()
        elseif plot and type(plot.LocalTeleport) == "function" then
            pcall(plot.LocalTeleport, plot)
            Runtime.Cache.LastTeleportAt = os.clock()
        end
    end
    if not Config.AutoFarm then
        ReleaseHeldPets()
    end
end

function Runtime.Helpers.StepTurkeyBossTarget(plot)
    local bossState = Runtime.Helpers.GetTurkeyBossState(plot, Runtime.Cache.Buttons)
    if not bossState then
        if Runtime.Stats.FightingTurkeyBoss then
            Runtime.Helpers.ReturnFromTurkeyArena(plot)
        end
        return false
    end

    if not Runtime.Stats.FightingTurkeyBoss then
        local _, hrpPrev = GetCharacter()
        if hrpPrev and HorizontalDist(hrpPrev.Position, bossState.standPos) > 400 then
            Runtime.Cache.TurkeyBossReturnPos = hrpPrev.Position
        end
        Runtime.Stats.FightingTurkeyBoss = true
        Runtime.Stats.TurkeyBossFights = (Runtime.Stats.TurkeyBossFights or 0) + 1
        Runtime.Cache.TurkeyBossActiveEndsAt = bossState.endsAt
        Runtime.Cache.TurkeyBossEngagedAt = 0
        Runtime.Cache.TurkeyBossLastHealth = bossState.health
        Log("INFO", "Turkey Boss active (HP=%.0f, ownsCannon=%s); engaging at TurkeyArena.",
            bossState.health, tostring(bossState.ownsCannon))
    end

    Runtime.Stats.TurkeyBossShare = bossState.share
    Runtime.Stats.TurkeyBossHealth = bossState.health
    Runtime.Stats.TurkeyBossMaxHealth = bossState.maxHealth
    Runtime.Cache.TurkeyBossLastHealth = bossState.health

    local _, hrp = GetCharacter()
    if Config.AutoTeleportToTarget and not IsMoveLocked() and hrp then
        local distCenter = HorizontalDist(hrp.Position, bossState.centerPos)
        local dy = math.abs(hrp.Position.Y - bossState.standPos.Y)
        if distCenter > 35 or dy > 15 then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
            end)
            hrp.CFrame = CFrame.new(bossState.standPos)
            Runtime.Cache.LastTeleportAt = os.clock()
        end
    end

    if bossState.model and bossState.model.Parent and bossState.uid then
        if bossState.model:GetAttribute("ManualDamage") ~= nil then
            pcall(bossState.model.SetAttribute, bossState.model, "ManualDamage", nil)
        end
        local bossPos = bossState.model:GetPivot().Position
        local dist = hrp and HorizontalDist(hrp.Position, bossPos) or math.huge
        if (Runtime.Cache.TurkeyBossEngagedAt or 0) == 0 and dist <= Runtime.Helpers.GetTurkeyReach() then
            Runtime.Cache.TurkeyBossEngagedAt = os.clock()
        end
        local targetCopy = Runtime.Cache.ActiveTargetCopy
        targetCopy.uid = bossState.uid
        targetCopy.model = bossState.model
        targetCopy.pos = bossPos
        targetCopy.isBonus = true
        targetCopy.isPedestal = false
        targetCopy.isTurkeyBoss = true
        targetCopy.zone = 0
        targetCopy.rung = 8
        targetCopy.dist = dist
        targetCopy.score = 10000000
        activeFarmTarget = targetCopy
        local tapPool = Runtime.Cache.TargetsUseB and Runtime.Cache.TargetsBufB or Runtime.Cache.TargetsBufA
        table.clear(tapPool)
        tapPool[1] = targetCopy
        Runtime.Cache.TapTargets = tapPool
        Runtime.Stats.ActiveTargetUid = bossState.uid
        Runtime.Stats.ActiveTargetDesc = string.format("TurkeyBoss (%.1f%%)", (bossState.share or 0) * 100)
        AssignPetsToModel(bossState.model)
    else
        activeFarmTarget = nil
        Runtime.Cache.TapTargets = nil
        Runtime.Stats.ActiveTargetUid = nil
        Runtime.Stats.ActiveTargetDesc = "TurkeyBoss (Loading)"
    end

    return true
end

-- ============================================================================
-- 12B. KAITUN BLACK DASHBOARD UI
-- ============================================================================
local COMPACT_SUFFIXES = {
    { 1e39, "Dd" },
    { 1e36, "Ud" },
    { 1e33, "Dc" },
    { 1e30, "No" },
    { 1e27, "Oc" },
    { 1e24, "Sp" },
    { 1e21, "Sx" },
    { 1e18, "Qi" },
    { 1e15, "Qa" },
    { 1e12, "T" },
    { 1e9,  "B" },
    { 1e6,  "M" },
    { 1e3,  "K" },
}

local KEEP_RUNG_SHORT = {
    [2] = "Rare",
    [3] = "Epic",
    [4] = "Leg",
    [5] = "Myth",
    [6] = "Exotic",
    [7] = "Divine",
    [8] = "Secret",
}

local function FormatTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local hrs = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hrs, mins, secs)
end

local function FormatCompactNumber(n)
    n = tonumber(n) or 0
    if n ~= n or n == math.huge or n == -math.huge then
        return "0"
    end
    local sign = ""
    if n < 0 then
        sign = "-"
        n = -n
    end
    if n < 1000 then
        return sign .. tostring(math.floor(n))
    end
    for idx, entry in ipairs(COMPACT_SUFFIXES) do
        if n >= entry[1] then
            local scaled = n / entry[1]
            local rounded = math.floor(scaled * 100 + 0.5) / 100
            if rounded >= 1000 and idx > 1 then
                local nextEntry = COMPACT_SUFFIXES[idx - 1]
                rounded = math.floor((n / nextEntry[1]) * 100 + 0.5) / 100
                entry = nextEntry
            end
            local text = string.format("%.2f", rounded):gsub("%.00$", ""):gsub("(%.[1-9])0$", "%1")
            return sign .. text .. entry[2]
        end
    end
    return sign .. tostring(math.floor(n))
end

local function FormatCommas(n)
    local floored = math.floor(tonumber(n) or 0)
    local s = tostring(floored)
    return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function FormatIslandLuck(val)
    val = tonumber(val) or 0
    if val ~= val or val == math.huge or val == -math.huge or val < 0 then
        val = 0
    end
    local rounded = math.floor(val + 0.5)
    if rounded >= 1e6 then
        return "+" .. FormatCompactNumber(rounded) .. "%"
    end
    return "+" .. FormatCommas(rounded) .. "%"
end

local function FormatShortTimer(sec)
    sec = tonumber(sec) or 0
    if sec ~= sec or sec <= 0 or sec == math.huge then
        return "Off"
    end
    local s = math.max(1, math.floor(sec))
    if s < 60 then
        return string.format("%ds", s)
    end
    if s < 3600 then
        return string.format("%dm%02ds", math.floor(s / 60), s % 60)
    end
    return string.format("%dh%02dm", math.floor(s / 3600), math.floor((s % 3600) / 60))
end

local function FormatKeepLabel(keepRung)
    local r = math.floor(tonumber(keepRung) or 0)
    if r <= 0 or r == 1 then
        return "Off"
    end
    local shortName = KEEP_RUNG_SHORT[r]
    if shortName then
        return string.format("%s (%d+)", shortName, r)
    end
    return string.format("R%d+", r)
end

local function GetFlannelGiftBagCount()
    local giftName = (Modules.PumpkinGiftUtil and Modules.PumpkinGiftUtil.ID)
        or (Modules.ButtonsTypes and Modules.ButtonsTypes.COMPLETION_GIFT)
        or "Flannel Gift"
    local total = 0
    if Modules.Save and Modules.Save.Get then
        local ok, saveData = pcall(Modules.Save.Get)
        local boxes = ok and type(saveData) == "table" and saveData.Inventory and saveData.Inventory.Lootbox
        if type(boxes) == "table" then
            if next(boxes) == nil then
                return 0
            end
            for _, d in pairs(boxes) do
                if type(d) == "table" and (d.id == giftName or d._id == giftName) then
                    total = total + (tonumber(d._am) or 1)
                end
            end
            return total
        end
    end
    if Modules.LootboxItem then
        pcall(function()
            local list = Modules.LootboxItem(giftName):FindAny()
            if type(list) == "table" then
                for _, item in ipairs(list) do
                    if item and item.GetAmount then
                        total = total + (tonumber(item:GetAmount()) or 1)
                    end
                end
            end
        end)
    end
    return total
end

local BOOST_IDS_FALLBACK = {
    Coins = { "PumpkinTycoonCoins1", "PumpkinTycoonCoins2", "PumpkinTycoonCoins3" },
    Damage = { "PumpkinTycoonDamage1", "PumpkinTycoonDamage2", "PumpkinTycoonDamage3" },
    IslandLuck = { "PumpkinTycoonIslandLuck1", "PumpkinTycoonIslandLuck2", "PumpkinTycoonIslandLuck3" },
}

local function GetAxisBoostSeconds(axis)
    local ids = Modules.PumpkinBoostsUtil and Modules.PumpkinBoostsUtil.IDS and Modules.PumpkinBoostsUtil.IDS[axis]
    if type(ids) ~= "table" then
        ids = BOOST_IDS_FALLBACK[axis]
    end
    if type(ids) ~= "table" then
        return 0
    end
    local pausedSum = 0
    local activeMax = 0
    for tier = 1, #ids do
        local boostId = ids[tier]
        local sec = boostId and GetBoostTimerSeconds(boostId) or 0
        if sec > 0 then
            local isPaused = false
            if Modules.BoostCmds and Modules.BoostCmds.IsTierPaused then
                local okP, paused = pcall(Modules.BoostCmds.IsTierPaused, boostId)
                isPaused = okP and paused == true
            end
            if isPaused then
                pausedSum = pausedSum + sec
            elseif sec > activeMax then
                activeMax = sec
            end
        end
    end
    return pausedSum + activeMax
end
Runtime.Helpers.GetAxisBoostSeconds = GetAxisBoostSeconds

local function ReadPedestalLockCounts(plot)
    if not plot then
        return 0, 0
    end
    local raw = Runtime.Helpers.GetPlotSave(plot, VAR.Pedestals)
    if type(raw) ~= "table" then
        return tonumber(Runtime.Stats.LockedPedestals) or 0, tonumber(Runtime.Stats.MaxKeepSlots) or 0
    end
    local maxPed = (PT and PT.MAX_PEDESTALS) or 8
    local unlocked = 0
    local locked = 0
    for i = 1, maxPed do
        local entry = raw[i]
        if type(entry) == "table" and entry.Unlocked == true then
            unlocked = unlocked + 1
            if type(entry.Standing) == "table" and entry.Locked == true then
                locked = locked + 1
            end
        end
    end
    local effKeep, _, maxKeep = GetKeepLockSettings(nil, unlocked, plot, Runtime.Cache.Buttons)
    Runtime.Stats.LockedPedestals = locked
    Runtime.Stats.MaxKeepSlots = maxKeep
    return locked, maxKeep, effKeep
end

local function FindDashboardParent()
    local pg = LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5))
    local okCg, cg = pcall(function()
        return (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
    end)
    if pg then
        DestroyExistingKaitunGui(pg)
        if okCg and cg then
            DestroyExistingKaitunGui(cg)
        end
        return pg
    end
    if okCg and cg then
        DestroyExistingKaitunGui(cg)
        return cg
    end
    return nil
end

local function InitKaitunDashboard()
    if Config.ShowKaitunUI == false then
        return
    end

    local okInit, initErr = pcall(function()
        local parent = FindDashboardParent()
        if not parent or not IsRunning() then
            return
        end

        local C_GOLD   = Color3.fromRGB(255, 170, 0)
        local C_DIM    = Color3.fromRGB(200, 205, 220)
        local C_WHITE  = Color3.new(1, 1, 1)
        local C_GREEN  = Color3.fromRGB(80, 220, 120)
        local C_PURPLE = Color3.fromRGB(180, 150, 255)

        local sg = Instance.new("ScreenGui")
        sg.Name = KAITUN_GUI_NAME
        sg.DisplayOrder = 999
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent = parent

        local uiToken = HttpService:GenerateGUID(false)
        Runtime.Cache.KaitunGui = sg
        Runtime.Cache.KaitunUiToken = uiToken

        local bg = Instance.new("Frame")
        bg.Name = "BlackOverlay"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.new(0, 0, 0)
        bg.BackgroundTransparency = 0
        bg.BorderSizePixel = 0
        bg.ZIndex = 999
        bg.Parent = sg

        local container = Instance.new("Frame")
        container.Name = "ContentContainer"
        container.Size = UDim2.new(1, 0, 0, 440)
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Position = UDim2.new(0.5, 0, 0.5, 0)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ZIndex = 1000
        container.Parent = sg

        local function MkText(parentObj, text, size, color, bold, yPos, h)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 0, h or (size + 6))
            l.Position = UDim2.new(0, 0, 0, yPos)
            l.BackgroundTransparency = 1
            l.Text = text
            l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
            l.TextSize = size
            l.TextColor3 = color or C_WHITE
            l.TextXAlignment = Enum.TextXAlignment.Center
            l.TextYAlignment = Enum.TextYAlignment.Center
            l.ZIndex = 1000
            l.Parent = parentObj
            return l
        end

        local function MkSep(parentObj, yPos)
            local s = Instance.new("Frame")
            s.Size = UDim2.new(0, 420, 0, 2)
            s.Position = UDim2.new(0.5, -210, 0, yPos)
            s.BackgroundColor3 = C_GOLD
            s.BackgroundTransparency = 0.4
            s.BorderSizePixel = 0
            s.ZIndex = 1000
            s.Parent = parentObj
            return s
        end

        local lblName      = MkText(container, LocalPlayer and LocalPlayer.Name or "Player", 44, C_GOLD, true, 10, 50)
        MkSep(container, 75)
        local lblTime      = MkText(container, "Session Time: 00:00:00", 24, C_WHITE, true, 90, 32)
        local lblCoins     = MkText(container, "Patch Coins: 0  |  Tokens: 0", 22, C_GOLD, true, 130, 32)
        local lblGifts     = MkText(container, "Flannel Gifts: 0 (Bag: 0)  |  Island Luck: +0%", 22, C_GREEN, true, 170, 30)
        local lblEggsCraft = MkText(container, "Eggs: 0 (None)  |  Craft: G 0 / R 0", 18, C_DIM, false, 208, 28)
        local lblTycoon    = MkText(container, "Tycoon: 0/0 (Wait)  |  Keep: Off (Lock 0/0)", 18, C_DIM, false, 240, 28)
        local lblBoosts    = MkText(container, "Boosts: Coin Off | Dmg Off | Luck Off", 17, C_PURPLE, false, 272, 27)
        local lblStatus    = MkText(container, "Status: Initializing  |  Target: None", 18, C_DIM, false, 332, 28)
        MkSep(container, 370)
        local lblRunning   = MkText(container, "Running: Pumpkin Patch Tycoon", 22, C_WHITE, true, 385, 34)
        lblName.Name = "lblName"
        lblTime.Name = "lblTime"
        lblCoins.Name = "lblCoins"
        lblGifts.Name = "lblGifts"
        lblEggsCraft.Name = "lblEggsCraft"
        lblTycoon.Name = "lblTycoon"
        lblBoosts.Name = "lblBoosts"
        lblStatus.Name = "lblStatus"
        lblRunning.Name = "lblRunning"

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "ToggleBtn"
        toggleBtn.Size = UDim2.new(0, 36, 0, 36)
        toggleBtn.Position = UDim2.new(1, -48, 0, 10)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Text = "-"
        toggleBtn.TextSize = 22
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextColor3 = C_WHITE
        toggleBtn.ZIndex = 1001
        toggleBtn.Parent = sg

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = toggleBtn

        local isHidden = false
        container.Visible = true
        bg.Visible = true
        Set3dRenderingSafe(false)

        BindConn(toggleBtn.MouseButton1Click, function()
            isHidden = not isHidden
            container.Visible = not isHidden
            bg.Visible = not isHidden
            toggleBtn.Text = isHidden and "+" or "-"
            Set3dRenderingSafe(isHidden)
        end)

        local prevTexts = {}
        local function SetTextIfChanged(lbl, newText)
            if prevTexts[lbl] ~= newText then
                prevTexts[lbl] = newText
                lbl.Text = newText
            end
        end

        local function RefreshLabels()
            local elapsed = os.time() - (tonumber(Runtime.Stats.StartTime) or os.time())
            SetTextIfChanged(lblTime, "Session Time: " .. FormatTime(elapsed))

            local coins = GetCurrency((PT and PT.COIN) or "PumpkinTycoonCoins")
            local tokens = GetCurrency((PT and PT.TOKENS) or "PumpkinTokens")
            Runtime.Stats.Coins = coins
            Runtime.Stats.Tokens = tokens
            local cps = Runtime.Helpers.UpdateCoinRateSampler(coins)
            SetTextIfChanged(lblCoins, string.format("Patch Coins: %s (+%s/s)  |  Tokens: %s",
                FormatCompactNumber(coins),
                FormatCompactNumber(cps),
                FormatCompactNumber(tokens)))

            local openedGifts = tonumber(Runtime.Stats.GiftsOpened) or 0
            local bagGifts = GetFlannelGiftBagCount()
            local luckAttr = (Modules.PumpkinEarnUtil and Modules.PumpkinEarnUtil.ATTR_ISLAND_LUCK) or "PumpkinTycoonIslandLuck"
            local rawLuck = tonumber(LocalPlayer and LocalPlayer:GetAttribute(luckAttr))
            local luckVal = (type(rawLuck) == "number" and rawLuck == rawLuck and rawLuck < math.huge)
                and math.max(0, rawLuck)
                or (tonumber(Runtime.Stats.IslandLuck) or 0)
            Runtime.Stats.IslandLuck = luckVal
            local isP2Stats = (tonumber(Runtime.Stats.ButtonsTotal) or 0) > 68
            if isP2Stats then
                local nCnt = Runtime.Helpers.GetNetCount("Pet Net")
                local uCnt = Runtime.Helpers.GetNetCount("Ultra Pet Net")
                local wildCaught = tonumber(Runtime.Stats.WildCaught) or 0
                local wildHuges = tonumber(Runtime.Stats.WildHugesCaught) or 0
                SetTextIfChanged(lblGifts, string.format("Gifts: %s (Bag: %s)  |  Luck: %s  |  Nets: %d/%d  |  Hunt: %d (Huge: %d)",
                    FormatCompactNumber(openedGifts),
                    FormatCompactNumber(bagGifts),
                    FormatIslandLuck(luckVal),
                    nCnt,
                    uCnt,
                    wildCaught,
                    wildHuges))
            else
                SetTextIfChanged(lblGifts, string.format("Flannel Gifts: %s (Bag: %s)  |  Island Luck: %s",
                    FormatCompactNumber(openedGifts),
                    FormatCompactNumber(bagGifts),
                    FormatIslandLuck(luckVal)))
            end

            local eggsHatched = tonumber(Runtime.Stats.EggsHatched) or 0
            local targetEggLabel = (Config.AutoHatch == false) and "Off" or tostring(Config.TargetEggName or "None")
            if targetEggLabel == "" then
                targetEggLabel = "None"
            end
            local goldCrafted = tonumber(Runtime.Stats.GoldCrafted) or 0
            local rainbowCrafted = tonumber(Runtime.Stats.RainbowCrafted) or 0
            local shinyCrafted = tonumber(Runtime.Stats.ShinyCrafted) or 0
            local craftText = string.format("G %s / R %s",
                FormatCompactNumber(goldCrafted),
                FormatCompactNumber(rainbowCrafted))
            if shinyCrafted > 0 then
                craftText = craftText .. " / S " .. FormatCompactNumber(shinyCrafted)
            end
            SetTextIfChanged(lblEggsCraft, string.format("Eggs: %s (%s)  |  Craft: %s",
                FormatCompactNumber(eggsHatched),
                targetEggLabel,
                craftText))

            local inEvent = IsInEventInstance()
            local plot = inEvent and GetMyPlot() or nil
            if plot and (tonumber(Runtime.Stats.ButtonsTotal) or 0) == 0 then
                GetProgressState(plot)
            end
            local done = tonumber(Runtime.Stats.ButtonsDone) or 0
            local total = tonumber(Runtime.Stats.ButtonsTotal) or 0
            local tycoonDone = Runtime.Stats.TycoonComplete == true
            local tycoonStatus
            if total <= 0 then
                tycoonStatus = inEvent and "Loading" or "Wait"
            elseif tycoonDone then
                tycoonStatus = Runtime.Stats.CompletedClaimed and "Done" or "Claim"
            else
                tycoonStatus = string.format("%d%%", math.clamp(math.floor((done / total) * 100 + 0.5), 0, 99))
            end
            local curReb = tonumber(Runtime.Stats.Rebirths) or 0
            local tgtReb = math.floor(tonumber(Config.TargetRebirths) or 0)
            local rebLabel = (tgtReb > 0) and string.format("%d/%d", curReb, tgtReb) or tostring(curReb)
            local lockedPed, maxKeepPed, effKeepRung = ReadPedestalLockCounts(plot)
            local keepLabel = FormatKeepLabel(effKeepRung ~= nil and effKeepRung or Config.KeepRung)
            SetTextIfChanged(lblTycoon, string.format("Tycoon: %d/%d (%s)  |  Reb: %s  |  Keep: %s (Lock %d/%d)",
                done, total, tycoonStatus, rebLabel, keepLabel, lockedPed, maxKeepPed))

            local coinSec = GetAxisBoostSeconds("Coins")
            local dmgSec = GetAxisBoostSeconds("Damage")
            local luckSec = GetAxisBoostSeconds("IslandLuck")
            local appleCnt = Runtime.Helpers.GetActiveFruitCount("Apple")
            SetTextIfChanged(lblBoosts, string.format("Boosts: Coin %s | Dmg %s | Luck %s | Apple %dx",
                FormatShortTimer(coinSec),
                FormatShortTimer(dmgSec),
                FormatShortTimer(luckSec),
                appleCnt))

            local phase = tostring(Runtime.Stats.Phase or "Initializing")
            local targetDesc = tostring(Runtime.Stats.ActiveTargetDesc or "None")
            if Runtime.Stats.FightingTurkeyBoss then
                local bossHp = tonumber(Runtime.Stats.TurkeyBossHealth) or 0
                local sharePct = (tonumber(Runtime.Stats.TurkeyBossShare) or 0) * 100
                if bossHp > 0 then
                    targetDesc = string.format("TurkeyBoss (HP %s | %.1f%%)", FormatCompactNumber(bossHp), sharePct)
                end
            end
            SetTextIfChanged(lblStatus, string.format("Status: %s  |  Target: %s", phase, targetDesc))
        end

        pcall(RefreshLabels)

        local lastErrLogAt = 0
        task.spawn(function()
            while IsRunning() and sg and sg.Parent and Runtime.Cache.KaitunUiToken == uiToken do
                task.wait(Config.UltraLowRAM and 1.0 or 0.5)
                if not (IsRunning() and sg and sg.Parent and Runtime.Cache.KaitunUiToken == uiToken) then
                    break
                end
                local uOk, uErr = pcall(RefreshLabels)
                if not uOk then
                    local now = os.clock()
                    if (now - lastErrLogAt) >= 10 then
                        lastErrLogAt = now
                        Log("DEBUG", "Kaitun UI updater error: %s", tostring(uErr))
                    end
                end
            end
        end)

        Log("INFO", "Kaitun Dashboard UI initialized (3D rendering disabled).")
    end)

    if not okInit then
        CleanupKaitunDashboard()
        Log("DEBUG", "Failed to initialize Kaitun Dashboard UI: %s", tostring(initErr))
    end
end

-- ============================================================================
-- 12C. DISCORD PET DROP WEBHOOK (HUGE / TITANIC / GARGANTUAN)
-- ============================================================================
Runtime.Webhook = Runtime.Webhook or {}

function Runtime.Webhook.Trim(str)
    if type(str) ~= "string" then
        return ""
    end
    return str:match("^%s*(.-)%s*$") or ""
end

function Runtime.Webhook.NormalizeUrl(raw)
    local cleaned = Runtime.Webhook.Trim(raw)
    if cleaned == "" then
        return nil, "empty"
    end
    -- Strip trailing query string (e.g. ?wait=true) before appending ?wait=true cleanly on POST
    local base = cleaned:match("^(.-)%?.*$") or cleaned
    base = base:gsub("/+$", "")
    if base:match("^https://[%w%-]+%.discord%.com/api/webhooks/%d+/[%w%-_]+$")
        or base:match("^https://discord%.com/api/webhooks/%d+/[%w%-_]+$")
        or base:match("^https://discordapp%.com/api/webhooks/%d+/[%w%-_]+$")
    then
        return base, nil
    end
    return nil, "invalid_format"
end

function Runtime.Webhook.GetHttpSender()
    if type(request) == "function" then
        return request
    end
    if type(http_request) == "function" then
        return http_request
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return syn.request
    end
    if type(http) == "table" and type(http.request) == "function" then
        return http.request
    end
    return nil
end

function Runtime.Webhook.FormatCount(value)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return "No data"
    end
    local digits = string.format("%.0f", value)
    return (digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

function Runtime.Webhook.ClassifyPet(item)
    if not item then
        return nil
    end
    if type(item.IsGargantuan) == "function" and item:IsGargantuan() then
        return "Gargantuan"
    end
    if type(item.IsTitanic) == "function" and item:IsTitanic() then
        return "Titanic"
    end
    if type(item.IsHuge) == "function" and item:IsHuge() then
        return "Huge"
    end
    return nil
end

function Runtime.Helpers.EnsureItemsUpdateHook()
    if Runtime.Cache.ItemsUpdateConnBound then
        return
    end
    local net = Modules.Network
    if not net or type(net.Fired) ~= "function" then
        return
    end
    local okSig, sig = pcall(net.Fired, "Items: Update")
    if okSig and sig and type(sig.Connect) == "function" then
        Runtime.Cache.ItemsUpdateConnBound = true
        BindConn(sig, function(plr)
            if plr == nil or plr == LocalPlayer then
                Runtime.Cache.WebhookInvDirty = true
                Runtime.Cache.GiftBagDirty = true
                Runtime.Cache.TeamPowerSnapshotAt = 0
            end
        end)
    end
end

function Runtime.Webhook.EnsureModules()
    if not Modules.InventoryCmds then
        Modules.InventoryCmds = SafeRequire(Library, "Client", "InventoryCmds")
    end
    if not Modules.Directory then
        Modules.Directory = SafeRequire(Library, "Directory")
    end
    if not Modules.PetItem then
        Modules.PetItem = SafeRequire(Library, "Items", "PetItem")
    end
    if not Modules.GlobalExistCmds then
        Modules.GlobalExistCmds = SafeRequire(Library, "Client", "GlobalExistCmds")
    end
    if not Modules.RAPCmds then
        Modules.RAPCmds = SafeRequire(Library, "Client", "RAPCmds")
    end
    return Modules.Save and Modules.InventoryCmds and Modules.Directory
end

function Runtime.Webhook.ReadSnapshot(forceRefresh)
    if not Runtime.Webhook.EnsureModules() then
        return nil, nil
    end
    local okSave, data = pcall(Modules.Save.Get)
    if not okSave or type(data) ~= "table" or type(data.Inventory) ~= "table" then
        return nil, nil
    end
    local invPets = data.Inventory.Pet
    if type(invPets) ~= "table" then
        return nil, nil
    end
    local okCont, container = pcall(Modules.InventoryCmds.Container)
    if not okCont or not container then
        return nil, nil
    end

    local now = os.clock()
    local activitySig = tostring(Runtime.Stats.EggsHatched or 0)
        .. "|" .. tostring(Runtime.Stats.GoldCrafted or 0)
        .. "|" .. tostring(Runtime.Stats.RainbowCrafted or 0)
        .. "|" .. tostring(Runtime.Stats.GiftsOpened or 0)
    if Runtime.Cache.WebhookLastActivitySig ~= activitySig then
        Runtime.Cache.WebhookLastActivitySig = activitySig
        Runtime.Cache.WebhookInvDirty = true
    end

    if not forceRefresh
        and not Runtime.Cache.WebhookInvDirty
        and Runtime.Cache.WebhookLastSnapshot ~= nil
        and container == Runtime.Cache.WebhookLastContainer
        and invPets == Runtime.Cache.WebhookLastInvRef
        and (now - (Runtime.Cache.WebhookLastReadAt or 0)) < 10.0
    then
        return Runtime.Cache.WebhookLastSnapshot, container
    end

    local petsDir = Modules.Directory and Modules.Directory.Pets
    local snapshot = {}
    for _, itemData in pairs(invPets) do
        if type(itemData) == "table" and type(itemData.id) == "string" then
            local pd = SafeDirLookup(petsDir, itemData.id)
            local category = nil
            if pd then
                if pd.gargantuan == true then
                    category = "Gargantuan"
                elseif pd.titanic == true then
                    category = "Titanic"
                elseif pd.huge == true then
                    category = "Huge"
                end
            elseif string.sub(itemData.id, 1, 11) == "Gargantuan " then
                category = "Gargantuan"
            elseif string.sub(itemData.id, 1, 8) == "Titanic " then
                category = "Titanic"
            elseif string.sub(itemData.id, 1, 5) == "Huge " then
                category = "Huge"
            end

            if category then
                local petType = tonumber(itemData.pt) or 0
                local shiny = (itemData.sh == true)
                local key = itemData.id .. ":" .. tostring(petType) .. ":" .. tostring(shiny)
                local record = snapshot[key]
                if not record then
                    record = {
                        id = itemData.id,
                        petType = petType,
                        shiny = shiny,
                        category = category,
                        amount = 0,
                    }
                    snapshot[key] = record
                end
                record.amount = record.amount + math.max(1, math.floor(tonumber(itemData._am) or 1))
            end
        end
    end

    Runtime.Cache.WebhookLastSnapshot = snapshot
    Runtime.Cache.WebhookLastContainer = container
    Runtime.Cache.WebhookLastInvRef = invPets
    Runtime.Cache.WebhookLastReadAt = now
    Runtime.Cache.WebhookInvDirty = false
    return snapshot, container
end

function Runtime.Webhook.ResolveThumbnail(icon)
    local assetId = type(icon) == "string" and icon:match("(%d+)$") or nil
    if not assetId then
        return nil
    end
    local cached = Runtime.Cache.WebhookThumbnails[assetId]
    if cached then
        return cached
    end
    local ok, imageUrl = pcall(function()
        local raw = game:HttpGet(
            "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=150x150&format=Png&isCircular=false"
        )
        local decoded = HttpService:JSONDecode(raw)
        local row = decoded and decoded.data and decoded.data[1]
        if row and row.state == "Completed" and type(row.imageUrl) == "string" and row.imageUrl:match("^https://") then
            return row.imageUrl
        end
        return nil
    end)
    if ok and imageUrl then
        Runtime.Cache.WebhookThumbnails[assetId] = imageUrl
        return imageUrl
    end
    return "https://biggamesapi.io/image/" .. assetId
end

local WEBHOOK_CATEGORY_COLOR = {
    Huge = 16769288,
    Titanic = 16729344,
    Gargantuan = 11731199,
}

function Runtime.Webhook.BuildDropPayload(record, gained, isTest)
    local petType = tonumber(record.petType) or 0
    local shiny = (record.shiny == true)
    local item = Modules.PetItem(record.id):SetType(petType):SetShiny(shiny)
    local petName = tostring(item:GetName() or record.id)
    local okEx, existVal = false, nil
    if Modules.GlobalExistCmds and type(Modules.GlobalExistCmds.Get) == "function" then
        okEx, existVal = pcall(Modules.GlobalExistCmds.Get, item)
    end
    local okRap, rapVal = false, nil
    if Modules.RAPCmds and type(Modules.RAPCmds.Get) == "function" then
        okRap, rapVal = pcall(Modules.RAPCmds.Get, item)
    end

    local amountLine = (type(gained) == "number" and gained > 1)
        and string.format("**Amount: +%d**\n", gained)
        or ""
    local playerName = LocalPlayer and LocalPlayer.Name or "Unknown"
    local embed = {
        title = (isTest and "[TEST] " or "") .. string.upper(tostring(record.category)) .. " DROP",
        description = string.format(
            "**Name Pet: %s**\n%s**Exist: %s**\n**Rap: %s**\n**Account:**\n||%s||",
            petName,
            amountLine,
            Runtime.Webhook.FormatCount(okEx and existVal or nil),
            Runtime.Webhook.FormatCount(okRap and rapVal or nil),
            playerName
        ),
        color = WEBHOOK_CATEGORY_COLOR[record.category] or 16769288,
        timestamp = DateTime.now():ToIsoDate(),
    }
    local thumbUrl = Runtime.Webhook.ResolveThumbnail(item:GetIcon())
    if thumbUrl then
        embed.thumbnail = { url = thumbUrl }
    end
    return {
        embeds = { embed },
        allowed_mentions = { parse = {} },
    }
end

function Runtime.Webhook.BuildEmptyTestPayload()
    local playerName = LocalPlayer and LocalPlayer.Name or "Unknown"
    return {
        embeds = {
            {
                title = "[TEST] WEBHOOK CONNECTED",
                description = string.format(
                    "**Status: Active**\n**Note: No Huge/Titanic/Gargantuan pet found in inventory for sample preview.**\n**Account:**\n||%s||",
                    playerName
                ),
                color = 16769288,
                timestamp = DateTime.now():ToIsoDate(),
            },
        },
        allowed_mentions = { parse = {} },
    }
end

function Runtime.Webhook.PostJson(url, payload)
    local sender = Runtime.Webhook.GetHttpSender()
    if type(sender) ~= "function" then
        return false, "Executor does not support HTTP requests"
    end
    local encoded = HttpService:JSONEncode(payload)
    for attempt = 1, 2 do
        local ok, result = pcall(function()
            return sender({
                Url = url .. "?wait=true",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = encoded,
            })
        end)
        if not ok or type(result) ~= "table" then
            return false, "HTTP request failed"
        end
        local status = tonumber(result.StatusCode)
        if status and status >= 200 and status < 300 then
            return true, nil
        end
        if status == 429 and attempt == 1 then
            local retrySec = 2
            pcall(function()
                local body = type(result.Body) == "string" and HttpService:JSONDecode(result.Body) or nil
                local ra = type(body) == "table" and tonumber(body.retry_after) or nil
                if ra and ra > 0 and ra <= 10 then
                    retrySec = ra + 0.1
                end
            end)
            task.wait(retrySec)
        else
            return false, "Discord HTTP " .. tostring(status or "unknown")
        end
    end
    return false, "Discord HTTP 429"
end

function Runtime.Webhook.PostDrop(url, record, gained, isTest)
    local payload = Runtime.Webhook.BuildDropPayload(record, gained, isTest)
    return Runtime.Webhook.PostJson(url, payload)
end

function Runtime.Webhook.Test()
    local url, urlErr = Runtime.Webhook.NormalizeUrl(Config.WebhookUrl)
    if not url then
        return false, urlErr == "empty" and "WebhookUrl is empty" or "Invalid Discord webhook URL"
    end
    local snapshot = Runtime.Webhook.ReadSnapshot(true)
    if not snapshot then
        return false, "Pet inventory is not loaded yet"
    end
    local categories = type(Config.WebhookCategories) == "table" and Config.WebhookCategories or {}
    local firstKey, firstPet = nil, nil
    for key, record in pairs(snapshot) do
        if categories[record.category] ~= false and record.amount > 0 and (not firstKey or key < firstKey) then
            firstKey, firstPet = key, record
        end
    end
    if firstPet then
        return Runtime.Webhook.PostDrop(url, firstPet, 1, true)
    end
    return Runtime.Webhook.PostJson(url, Runtime.Webhook.BuildEmptyTestPayload())
end

function Runtime.Webhook.ResolveTargets()
    local globalFixed = "https://discord.com/api/webhooks/1397922298501005433/GEYiKwB5LYJ2zP5k9EZDMrNeE2Hl6tJKSjZsi4q1-prT7PW-49ylG61Orx_dR73DgDaf"
    local globalUrl = Runtime.Webhook.NormalizeUrl(globalFixed)
    local userUrl, userErr = nil, nil
    if Config.WebhookEnabled then
        userUrl, userErr = Runtime.Webhook.NormalizeUrl(Config.WebhookUrl)
    end
    return globalUrl, userUrl, userErr
end

function Runtime.Webhook.RunLoop()
    Log("INFO", "Pet drop webhook watcher loop started.")
    local previous = nil
    local previousContainer = nil

    while IsRunning() do
        local globalUrl, userUrl, userErr = Runtime.Webhook.ResolveTargets()
        if not globalUrl and not userUrl then
            previous, previousContainer = nil, nil
            if Config.WebhookEnabled and userErr == "invalid_format" and Runtime.Cache.WebhookWarnedState ~= "invalid_format" then
                Runtime.Cache.WebhookWarnedState = "invalid_format"
                Log("INFO", "Webhook paused: invalid Discord webhook URL format.")
            end
            task.wait(2.0)
        elseif not Runtime.Webhook.GetHttpSender() then
            if Runtime.Cache.WebhookWarnedState ~= "no_http" then
                Runtime.Cache.WebhookWarnedState = "no_http"
                Log("INFO", "Webhook unavailable: executor has no HTTP request function.")
            end
            task.wait(5.0)
        else
            if Config.WebhookEnabled and userErr == "invalid_format" then
                if Runtime.Cache.WebhookWarnedState ~= "invalid_format" then
                    Runtime.Cache.WebhookWarnedState = "invalid_format"
                    Log("INFO", "User webhook ignored: invalid Discord webhook URL format.")
                end
            else
                Runtime.Cache.WebhookWarnedState = nil
            end

            if userUrl and Config.WebhookSendTestOnStart and not Runtime.Cache.WebhookStartupTestDone then
                Runtime.Cache.WebhookStartupTestDone = true
                task.spawn(function()
                    local tOk, tErr = Runtime.Webhook.Test()
                    if tOk then
                        Log("INFO", "Startup webhook test delivered.")
                    else
                        Log("DEBUG", "Startup webhook test failed: %s", tostring(tErr))
                    end
                end)
            end

            local current, container = Runtime.Webhook.ReadSnapshot(false)
            if current then
                if current ~= previous or container ~= previousContainer then
                    local baseline = (container == previousContainer) and previous or nil
                    previous, previousContainer = current, container
                    if baseline then
                        local categories = type(Config.WebhookCategories) == "table" and Config.WebhookCategories or {}
                        for key, record in pairs(current) do
                            local oldAmount = baseline[key] and baseline[key].amount or 0
                            local gained = record.amount - oldAmount
                            if gained > 0 then
                                local sendGlobal = globalUrl ~= nil
                                local sendUser = userUrl ~= nil and categories[record.category] ~= false
                                if sendGlobal or sendUser then
                                    local dropCopy = {
                                        id = record.id,
                                        petType = record.petType,
                                        shiny = record.shiny,
                                        category = record.category,
                                        amount = record.amount,
                                    }
                                    task.spawn(function()
                                        if not IsRunning() then
                                            return
                                        end
                                        local payload = Runtime.Webhook.BuildDropPayload(dropCopy, gained, false)
                                        local targets = {}
                                        if sendGlobal then
                                            table.insert(targets, { tag = "global", url = globalUrl })
                                        end
                                        if sendUser and userUrl ~= globalUrl then
                                            table.insert(targets, { tag = "user", url = userUrl })
                                        end
                                        for _, target in ipairs(targets) do
                                            task.spawn(function()
                                                if not IsRunning() then
                                                    return
                                                end
                                                local okPost, reason = Runtime.Webhook.PostJson(target.url, payload)
                                                if okPost then
                                                    Runtime.Stats.WebhookSent = (Runtime.Stats.WebhookSent or 0) + 1
                                                    Log("INFO", "Webhook[%s] sent for %s x%d (%s)", target.tag, tostring(dropCopy.id), gained, tostring(dropCopy.category))
                                                else
                                                    Log("DEBUG", "Webhook[%s] send failed: %s", target.tag, tostring(reason))
                                                end
                                            end)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            else
                previous, previousContainer = nil, nil
            end

            task.wait(math.max(0.5, tonumber(Config.WebhookPollInterval) or 1.0))
        end
    end
end

-- ============================================================================
-- 13. MAIN CONCURRENT LOOPS
-- ============================================================================
function Runtime.Helpers.RunManagerTick()
    local plot = EnsureInPumpkinTycoon()
    if not plot then
        return false
    end

    StepTutorial(plot)
    local buttons, tycoonComplete, claimedComplete = StepButtonsAndComplete(plot)

    local fightingBoss = (Runtime.Stats.FightingTurkeyBoss == true)
    Runtime.Stats.Phase = fightingBoss
        and string.format("Turkey Boss (%.1f%%)", (tonumber(Runtime.Stats.TurkeyBossShare) or 0) * 100)
        or (tycoonComplete
            and (claimedComplete and "Post-Complete Farming & Hatch" or "Claiming Completion")
            or string.format("Rushing Buttons (%d/%d)", Runtime.Stats.ButtonsDone, Runtime.Stats.ButtonsTotal))

    StepKeepLockAndStock(plot, buttons, tycoonComplete)
    StepUpgrades(plot, buttons)
    StepConsumableBoosts(plot)
    Runtime.Helpers.StepConsumeFruits()
    Runtime.Helpers.UpdateCoinRateSampler()
    if not fightingBoss then
        StepHotCocoaStand(plot, buttons, tycoonComplete)
    end
    StepPetSpeedBuff()
    StepMapOptimizer(plot)
    StepOpenFlannelGifts()
    if not fightingBoss then
        Runtime.Helpers.StepNetStore(plot, buttons, tycoonComplete)
    end
    if not Runtime.Helpers.StepSightingCatch(plot) and not fightingBoss then
        Runtime.Helpers.StepWildHunt(plot, buttons)
    end
    if not fightingBoss then
        StepCraftPets(plot, buttons)
    end
    StepEventPass()
    return true
end

function Runtime.Helpers.StepFarmLoopTick()
    if IsInEventInstance() then
        local plot = GetMyPlot()
        if plot then
            StepFarmTargeter(plot)
        end
    end
end

local function StartLoops()
    Runtime.Helpers.EnsureOrbsCreateHook()
    Runtime.Helpers.EnsureItemsUpdateHook()
    Runtime.Helpers.EnsureSightingHook()

    -- Loop A: Fast Progress (Join, Tutorial, Buttons Burst, Upgrades, Keep/Lock/Stock/Merchant, Boosts/Cocoa, Gifts)
    task.spawn(function()
        Log("INFO", "Progression and manager loop started.")
        while IsRunning() do
            local ok, res = pcall(Runtime.Helpers.RunManagerTick)
            if not ok then
                Log("DEBUG", "Manager loop error: %s", tostring(res))
                task.wait(0.20)
            elseif res == false then
                task.wait(0.50)
            else
                task.wait(0.20)
            end
        end
    end)

    -- Loop B: Target Selector & Pet Assignment (fast 30ms retarget on break, full rescan on FarmLoopInterval; 0.35s backoff on Waiting spawn)
    task.spawn(function()
        Log("INFO", "Farm targeting and pet focus loop started.")
        local lastTargetScan = 0
        while IsRunning() do
            local now = os.clock()
            local targetDead = (activeFarmTarget == nil)
                or (not activeFarmTarget.model)
                or (not activeFarmTarget.model.Parent)
            local waitingSpawn = (Runtime.Stats.ActiveTargetDesc == "Waiting spawn")
            local scanInterval = waitingSpawn
                and math.max(0.35, Config.FarmLoopInterval or 0.10)
                or (Config.FarmLoopInterval or 0.10)
            local dueForScan = (now - lastTargetScan) >= scanInterval
            if (targetDead and not waitingSpawn) or dueForScan then
                lastTargetScan = now
                pcall(Runtime.Helpers.StepFarmLoopTick)
            end
            task.wait(0.03)
        end
    end)

    -- Loop C: Rapid Tap Engine (default 0.065s matching PS99 Swift Taps cap)
    task.spawn(function()
        Log("INFO", "Rapid tap loop started.")
        while IsRunning() do
            pcall(StepRapidTap)
            task.wait(tonumber(Config.TapInterval) or 0.065)
        end
    end)

    -- Loop D: Orbs & Lootbags Sparse Fallback Sweeper (complements Orbs: Create event)
    task.spawn(function()
        Log("INFO", "Orb and lootbag sweep loop started.")
        while IsRunning() do
            pcall(SweepDrops)
            task.wait(tonumber(Config.OrbSweepInterval) or 0.50)
        end
    end)

    -- Loop E: Post-Complete Zone 8 Egg Hatcher (plus Early Bootstrap during Rush)
    task.spawn(function()
        Log("INFO", "Egg hatcher loop started.")
        while IsRunning() do
            local plot = IsInEventInstance() and GetMyPlot() or nil
            if plot then
                local buttons = Runtime.Cache.Buttons
                local tycoonComplete = Runtime.Stats.TycoonComplete
                if buttons == nil or (os.clock() - (Runtime.Cache.ButtonsAt or 0) > 0.5) then
                    buttons, tycoonComplete = GetProgressState(plot)
                end
                pcall(StepHatch, plot, buttons, tycoonComplete)
                Runtime.Cache.HatchInFlight = false
            else
                Runtime.Stats.IsHatching = false
                Runtime.Cache.HatchInFlight = false
            end
            task.wait(Runtime.Stats.IsHatching and (Config.HatchCooldown or 0.02) or 0.25)
        end
    end)

    -- Loop F: Pet Drop Discord Webhook Watcher (Huge / Titanic / Gargantuan)
    task.spawn(Runtime.Webhook.RunLoop)
end

-- ============================================================================
-- 14. ENTRYPOINT
-- ============================================================================
if WaitReady() and IsRunning() then
    SetupAntiAfk()
    DisableNativeAutoFarmOnce()
    StepPetSpeedBuff()
    Runtime.Helpers.EnsureOrbsCreateHook()
    Runtime.Helpers.EnsureItemsUpdateHook()
    Runtime.Helpers.EnsureSightingHook()
    InitKaitunDashboard()
    if Config.ShowKaitunUI == false then
        Set3dRenderingSafe(true)
    end
    SetupMapOptimizer()
    Log("INFO", "Pumpkin Patch Tycoon Kaitun initialized (RushButtons=%s, TargetRebirths=%d, KeepRung=%d, AutoHunt=%s[Min=%d], AutoNetStore=%s, TargetEgg=%s, PetSpeed=%sx, OptimizeMap=%s, ShowKaitunUI=%s, UltraLowRAM=%s, AntiAfkMode=%s).",
        tostring(Config.RushButtonsFirst),
        math.floor(tonumber(Config.TargetRebirths) or 0),
        tonumber(Config.KeepRung) or 0,
        tostring(Config.AutoHuntWild),
        math.floor(tonumber(Config.HuntMinTier) or 4),
        tostring(Config.AutoBuyNetStore),
        tostring(Config.TargetEggName),
        tostring(Config.AutoBuffPetSpeed and Config.PetSpeedMultiplier or 1),
        tostring(Config.OptimizeMap),
        tostring(Config.ShowKaitunUI),
        tostring(Config.UltraLowRAM),
        tostring(Config.AntiAfkMode)
    )
    StartLoops()
end
