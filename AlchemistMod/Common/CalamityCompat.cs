using Terraria;
using Terraria.ModLoader;

namespace AlchemistMod.Common
{
	/// <summary>
	/// Safe helpers for talking to Calamity. Everything here works (and does nothing)
	/// when Calamity is not installed, so the mod never hard-depends on it.
	/// </summary>
	public static class CalamityCompat
	{
		public const string ModName = "CalamityMod";

		public static bool Loaded => ModLoader.HasMod(ModName);

		/// <summary>Finds a Calamity item by its internal name. Returns false if Calamity or the item is missing.</summary>
		public static bool TryGetItem(string internalName, out int type)
		{
			type = 0;
			if (ModLoader.TryGetMod(ModName, out Mod calamity) && calamity.TryFind(internalName, out ModItem item))
			{
				type = item.Type;
				return true;
			}
			return false;
		}

		/// <summary>
		/// Asks Calamity whether a boss was defeated, e.g. "providence" or "devourerofgods".
		/// If Calamity changes its API and the call fails, falls back to "Moon Lord defeated"
		/// so the items are never locked forever.
		/// </summary>
		public static bool Downed(string boss)
		{
			if (!ModLoader.TryGetMod(ModName, out Mod calamity))
				return false;

			try
			{
				if (calamity.Call("GetBossDowned", boss) is bool downed)
					return downed;
			}
			catch
			{
				// ignored, use fallback below
			}
			return NPC.downedMoonLord;
		}
	}
}
