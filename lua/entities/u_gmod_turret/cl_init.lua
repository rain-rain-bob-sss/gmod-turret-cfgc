
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable	= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

/*---------------------------------------------------------
   Overridden because I want to show the name of the 
   player that spawned it..
---------------------------------------------------------*/
surface.CreateFont( "YKTURRETKILLICON", {
	font = "Arial", -- On Windows/macOS, use the font-name which is shown to you by your operating system Font Viewer. On Linux, use the file name
	extended = false,
	size = 20,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = true,
} )
killicon.AddFont("gmod_turret","YKTURRETKILLICON","#gmod_turret",Color(255,255,0),1)
function ENT:GetOverlayText()

   local n="\nHold Shift to view more info."
   if(input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT))then
      local dmg=math.floor(self:GetNWString("Damage"))
      local delay=self:GetNWString("Delay")
      local force=math.floor(self:GetNWString("Force"))
      local num=math.floor(self:GetNWString("NumBullets"))
      local spread=self:GetNWString("Spread")
      local toggle=self:GetNWString("Toggle") and "Yes" or "No"
      --local pitch=self:GetNWBool("Pitch")
      local sound=self:GetNWString("Sound")
      sound=string.gsub(sound,"\\","")
      sound=string.sub(sound,1,128)
      --local me=self:GetNWBool("Muzzle") and "是" or "不"
      --local loop=self:GetNWBool("LoopSound") and "循環" or "不循環"
      local tbl={
         ["Damage:"]=dmg,
         ["Delay:"]=delay,
         ["Force:"]=force,
         ["NumBullets:"]=num,
         ["Spread:"]=spread,
         ["Toggle:"]=toggle,
         --["音高:"]=pitch,
         ["Sound:"]=sound,
         --["槍口特效:"]=me,
         --["音效循環:"]=loop,
         ["Muzzle Flash:"]=self:GetNWString("MuzzleFlash_ENT"),
      }
      n="\n"
      local num = 0
      for i,v in pairs(tbl)do
         num = num + 1
         n=n..i..tostring(v)
         if num ~= 8 then 
            n = n.."\n"
         end
      end
   end
	return self:GetPlayerName()..n
	
end
