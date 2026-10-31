using System.Collections.Generic;
using AlchemistMod.Common;
using Terraria;
using Terraria.GameContent.Bestiary;
using Terraria.GameContent.Personalities;
using Terraria.ID;
using Terraria.Localization;
using Terraria.ModLoader;
using Terraria.Utilities;

namespace AlchemistMod.Content.NPCs
{
	[AutoloadHead]
	public class Alchemist : ModNPC
	{
		// Shop pages. "Next Page" cycles through the ones that are unlocked.
		private const string PotionsShop = "Potions";
		private const string UtilityShop = "Utility";
		private const string CalamityShop = "Calamity";
		private static readonly string[] Pages = { PotionsShop, UtilityShop, CalamityShop };
		private static int currentPage;

		public override void SetStaticDefaults()
		{
			Main.npcFrameCount[Type] = 25;
			NPCID.Sets.ExtraFramesCount[Type] = 9;
			NPCID.Sets.AttackFrameCount[Type] = 4;
			NPCID.Sets.DangerDetectRange[Type] = 700;
			NPCID.Sets.AttackType[Type] = 0; // throws things
			NPCID.Sets.AttackTime[Type] = 60;
			NPCID.Sets.AttackAverageChance[Type] = 30;
			NPCID.Sets.HatOffsetY[Type] = 4;

			NPCID.Sets.NPCBestiaryDrawOffset.Add(Type, new NPCID.Sets.NPCBestiaryDrawModifiers { Velocity = 1f });

			NPC.Happiness
				.SetBiomeAffection<JungleBiome>(AffectionLevel.Like)     // herbs everywhere
				.SetBiomeAffection<SnowBiome>(AffectionLevel.Dislike)    // potions freeze
				.SetNPCAffection(NPCID.Dryad, AffectionLevel.Love)
				.SetNPCAffection(NPCID.WitchDoctor, AffectionLevel.Like)
				.SetNPCAffection(NPCID.Demolitionist, AffectionLevel.Dislike) // explosions near glassware
				.SetNPCAffection(NPCID.Clothier, AffectionLevel.Hate);
		}

		public override void SetDefaults()
		{
			NPC.townNPC = true;
			NPC.friendly = true;
			NPC.width = 18;
			NPC.height = 40;
			NPC.aiStyle = NPCAIStyleID.Passive;
			NPC.damage = 10;
			NPC.defense = 15;
			NPC.lifeMax = 250;
			NPC.HitSound = SoundID.NPCHit1;
			NPC.DeathSound = SoundID.NPCDeath1;
			NPC.knockBackResist = 0.5f;
			AnimationType = NPCID.Guide;
		}

		public override void SetBestiary(BestiaryDatabase database, BestiaryEntry bestiaryEntry)
		{
			bestiaryEntry.Info.AddRange(new IBestiaryInfoElement[]
			{
				BestiaryDatabaseNPCsPopulator.CommonTags.SpawnConditions.Biomes.Surface,
				new FlavorTextBestiaryInfoElement("Mods.AlchemistMod.Bestiary.Alchemist"),
			});
		}

		// Moves in once the Eater of Worlds or the Brain of Cthulhu is defeated.
		public override bool CanTownNPCSpawn(int numTownNPCs) => NPC.downedBoss2;

		public override List<string> SetNPCNameList() => new()
		{
			"Paracel", "Nicolas", "Hermes", "Albertus", "Mortimer", "Bubbles", "Fizzwick", "Thaddeus", "Elixa", "Corvin",
		};

		public override string GetChat()
		{
			var chat = new WeightedRandom<string>();
			chat.Add("Healing potions, fresh from the cauldron! Mostly fresh.");
			chat.Add("Don't drink the green one. Or do. I need the data.");
			chat.Add("A Wormhole potion and a friend, and you can be anywhere. Well, anywhere your friend is.");
			chat.Add("If you see anything bubbling in my room, don't touch it.");

			if (Main.hardMode)
				chat.Add("The world has changed, and so have my recipes. Take a look!");
			if (NPC.downedPlantera)
				chat.Add("That jungle flower had wonderful petals. Perfect for a Wrath potion.");
			if (NPC.downedMoonLord)
				chat.Add("Now that the Moon Lord is gone, I can brew everything. Every single potion!");

			int dryad = NPC.FindFirstNPC(NPCID.Dryad);
			if (dryad >= 0)
				chat.Add($"{Main.npc[dryad].GivenName} grows the best Daybloom. Don't tell her I said that.");

			if (CalamityCompat.Loaded)
				chat.Add("I've started brewing some... stranger potions lately. Check my other page.");

			return chat;
		}

		private static bool PageUnlocked(int page) => Pages[page] switch
		{
			PotionsShop => true,
			UtilityShop => NPC.downedMoonLord,
			CalamityShop => CalamityCompat.Loaded,
			_ => false,
		};

		private static int UnlockedPageCount()
		{
			int count = 0;
			for (int i = 0; i < Pages.Length; i++)
				if (PageUnlocked(i))
					count++;
			return count;
		}

		public override void SetChatButtons(ref string button, ref string button2)
		{
			if (!PageUnlocked(currentPage))
				currentPage = 0;

			button = Language.GetTextValue("LegacyInterface.28"); // "Shop"
			if (UnlockedPageCount() > 1)
			{
				button += $" ({Pages[currentPage]})";
				button2 = "Next Page";
			}
		}

		public override void OnChatButtonClicked(bool firstButton, ref string shopName)
		{
			if (firstButton)
			{
				shopName = Pages[currentPage];
				return;
			}

			do
				currentPage = (currentPage + 1) % Pages.Length;
			while (!PageUnlocked(currentPage));

			Main.npcChatText = $"Here are my {Pages[currentPage].ToLower()} potions.";
		}

		public override void AddShops()
		{
			// ===== Page 1: Potions (progression) =====
			var potions = new NPCShop(Type, PotionsShop)
				// Pre-Hardmode (he moves in after the evil boss)
				.Add(ItemID.HealingPotion)
				.Add(ItemID.RegenerationPotion)
				.Add(ItemID.WormholePotion)
				// After the Wall of Flesh: 3 more
				.Add(ItemID.GreaterHealingPotion, Condition.Hardmode)
				.Add(ItemID.IronskinPotion, Condition.Hardmode)
				.Add(ItemID.SwiftnessPotion, Condition.Hardmode)
				// After Plantera
				.Add(ItemID.RestorationPotion, Condition.DownedPlantera)
				.Add(ItemID.EndurancePotion, Condition.DownedPlantera)
				.Add(ItemID.LifeforcePotion, Condition.DownedPlantera)
				.Add(ItemID.HeartreachPotion, Condition.DownedPlantera)
				.Add(ItemID.WrathPotion, Condition.DownedPlantera)
				.Add(ItemID.RagePotion, Condition.DownedPlantera)
				.Add(ItemID.InfernoPotion, Condition.DownedPlantera)
				// After the Moon Lord: everything else
				.Add(ItemID.LesserHealingPotion, Condition.DownedMoonLord)
				.Add(ItemID.SuperHealingPotion, Condition.DownedMoonLord)
				.Add(ItemID.LesserRestorationPotion, Condition.DownedMoonLord)
				.Add(ItemID.LesserManaPotion, Condition.DownedMoonLord)
				.Add(ItemID.ManaPotion, Condition.DownedMoonLord)
				.Add(ItemID.GreaterManaPotion, Condition.DownedMoonLord)
				.Add(ItemID.SuperManaPotion, Condition.DownedMoonLord)
				.Add(ItemID.BattlePotion, Condition.DownedMoonLord)
				.Add(ItemID.ArcheryPotion, Condition.DownedMoonLord)
				.Add(ItemID.AmmoReservationPotion, Condition.DownedMoonLord)
				.Add(ItemID.MagicPowerPotion, Condition.DownedMoonLord)
				.Add(ItemID.ManaRegenerationPotion, Condition.DownedMoonLord)
				.Add(ItemID.SummoningPotion, Condition.DownedMoonLord)
				.Add(ItemID.ThornsPotion, Condition.DownedMoonLord)
				.Add(ItemID.TitanPotion, Condition.DownedMoonLord)
				.Add(ItemID.ObsidianSkinPotion, Condition.DownedMoonLord)
				.Add(ItemID.GravitationPotion, Condition.DownedMoonLord);
			potions.Register();

			// ===== Page 2: Utility (unlocks after the Moon Lord) =====
			// A shop holds at most 40 items, so "all potions" is split across pages.
			new NPCShop(Type, UtilityShop)
				.Add(ItemID.RecallPotion)
				.Add(ItemID.TeleportationPotion)
				.Add(ItemID.PotionOfReturn)
				.Add(ItemID.SpelunkerPotion)
				.Add(ItemID.MiningPotion)
				.Add(ItemID.ShinePotion)
				.Add(ItemID.NightOwlPotion)
				.Add(ItemID.HunterPotion)
				.Add(ItemID.TrapsightPotion) // Dangersense
				.Add(ItemID.BiomeSightPotion)
				.Add(ItemID.BuilderPotion)
				.Add(ItemID.FishingPotion)
				.Add(ItemID.CratePotion)
				.Add(ItemID.SonarPotion)
				.Add(ItemID.FeatherfallPotion)
				.Add(ItemID.WaterWalkingPotion)
				.Add(ItemID.GillsPotion)
				.Add(ItemID.FlipperPotion)
				.Add(ItemID.InvisibilityPotion)
				.Add(ItemID.CalmingPotion)
				.Add(ItemID.WarmthPotion)
				.Add(ItemID.GenderChangePotion)
				.Add(ItemID.LovePotion)
				.Add(ItemID.StinkPotion)
				.Add(ItemID.LuckPotionLesser)
				.Add(ItemID.LuckPotion)
				.Add(ItemID.LuckPotionGreater)
				.Register();

			// ===== Page 3: Calamity (only if Calamity is installed) =====
			if (CalamityCompat.Loaded)
				AddCalamityShop();
		}

		private void AddCalamityShop()
		{
			var shop = new NPCShop(Type, CalamityShop);
			var downedProvidence = new Condition("Mods.AlchemistMod.Conditions.DownedProvidence", () => CalamityCompat.Downed("providence"));
			var downedDoG = new Condition("Mods.AlchemistMod.Conditions.DownedDoG", () => CalamityCompat.Downed("devourerofgods"));

			// Pre-Hardmode
			AddCalamity(shop, "BoundingPotion");
			AddCalamity(shop, "CalciumPotion");
			AddCalamity(shop, "SulphurskinPotion");
			AddCalamity(shop, "TeslaPotion");
			AddCalamity(shop, "PotionofOmniscience");
			AddCalamity(shop, "ZenPotion");
			AddCalamity(shop, "ZergPotion");
			AddCalamity(shop, "AnechoicCoating");

			// After the Wall of Flesh
			AddCalamity(shop, "FlaskOfCrumbling", Condition.Hardmode);
			AddCalamity(shop, "FlaskOfBrimstone", Condition.Hardmode);
			AddCalamity(shop, "SoaringPotion", Condition.Hardmode);
			AddCalamity(shop, "GravityNormalizerPotion", Condition.Hardmode);
			AddCalamity(shop, "ShadowPotion", Condition.Hardmode);
			AddCalamity(shop, "TitanScalePotion", Condition.Hardmode);
			AddCalamity(shop, "TriumphPotion", Condition.Hardmode);

			// After Plantera
			AddCalamity(shop, "PhotosynthesisPotion", Condition.DownedPlantera);
			AddCalamity(shop, "CadancePotion", Condition.DownedPlantera);
			AddCalamity(shop, "PenumbraPotion", Condition.DownedPlantera);
			AddCalamity(shop, "FlaskOfHolyFlames", Condition.DownedPlantera);
			AddCalamity(shop, "AstralInjection", Condition.DownedPlantera);
			AddCalamity(shop, "YharimsStimulants", Condition.DownedPlantera);

			// After the Moon Lord
			AddCalamity(shop, "CeaselessHungerPotion", Condition.DownedMoonLord);
			AddCalamity(shop, "HolyWrathPotion", Condition.DownedMoonLord);
			AddCalamity(shop, "ProfanedRagePotion", Condition.DownedMoonLord);
			AddCalamity(shop, "DraconicElixir", Condition.DownedMoonLord);

			// Calamity's stronger healing potions follow Calamity's own progression
			// so they don't break its balance.
			AddCalamity(shop, "SupremeHealingPotion", Condition.DownedMoonLord, downedProvidence);
			AddCalamity(shop, "OmegaHealingPotion", Condition.DownedMoonLord, downedDoG);

			shop.Register();
		}

		private void AddCalamity(NPCShop shop, string internalName, params Condition[] conditions)
		{
			// Skip items Calamity renamed or removed instead of crashing.
			if (CalamityCompat.TryGetItem(internalName, out int type))
				shop.Add(type, conditions);
			else
				Mod.Logger.Info($"Calamity item '{internalName}' not found, skipping it in the Alchemist's shop.");
		}

		// ===== Fighting: throws poisoned knives at nearby enemies =====
		public override void TownNPCAttackStrength(ref int damage, ref float knockback)
		{
			damage = NPC.downedMoonLord ? 60 : Main.hardMode ? 30 : 15;
			knockback = 3f;
		}

		public override void TownNPCAttackCooldown(ref int cooldown, ref int randExtraCooldown)
		{
			cooldown = 30;
			randExtraCooldown = 30;
		}

		public override void TownNPCAttackProj(ref int projType, ref int attackDelay)
		{
			projType = ProjectileID.PoisonedKnife;
			attackDelay = 1;
		}

		public override void TownNPCAttackProjSpeed(ref float multiplier, ref float gravityCorrection, ref float randomOffset)
		{
			multiplier = 10f;
			randomOffset = 1f;
		}
	}
}
