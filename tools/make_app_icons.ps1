param(
  [string]$SourceImage = "D:\codex program\ig_0f6ccc993b8eac86016a087a8110708191b4607fd6376ae342.png",
  [int]$CropX = 128,
  [int]$CropY = 112,
  [int]$CropSize = 998,
  [double]$IconScale = 0.82,
  [int]$OffsetX = -10,
  [int]$OffsetY = 8,
  [int]$Supersample = 4
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Code = @'
using System;
using System.IO;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class AppIconMaker {
  public static void Make(string root, string sourceImage, int cropX, int cropY, int cropSize, double iconScale, int offsetX, int offsetY, int supersample) {
    Directory.CreateDirectory(Path.Combine(root, "assets", "images"));
    Directory.CreateDirectory(Path.Combine(root, "build", "icon_work"));
    using (var src = Image.FromFile(sourceImage)) {
      SaveRoundPng(src, 1024, Path.Combine(root, "assets", "images", "brand_mark.png"), cropX, cropY, cropSize, iconScale, offsetX, offsetY, supersample);
      SaveRoundPng(src, 1024, Path.Combine(root, "assets", "images", "app_icon.png"), cropX, cropY, cropSize, iconScale, offsetX, offsetY, supersample);
      var sizes = new int[] { 16, 24, 32, 48, 64, 128, 256 };
      var pngs = new List<Tuple<int, byte[]>>();
      foreach (var size in sizes) {
        var path = Path.Combine(root, "build", "icon_work", "icon_" + size + ".png");
        SaveRoundPng(src, size, path, cropX, cropY, cropSize, iconScale, offsetX, offsetY, supersample);
        pngs.Add(Tuple.Create(size, File.ReadAllBytes(path)));
      }
      SaveIco(Path.Combine(root, "app_icon.ico"), pngs);
      SaveIco(Path.Combine(root, "windows", "runner", "resources", "app_icon.ico"), pngs);
      SaveIco(Path.Combine(root, "desktop_lyric", "windows", "runner", "resources", "app_icon.ico"), pngs);
    }
  }

  static void SaveRoundPng(Image src, int finalSize, string path, int cropX, int cropY, int cropSize, double iconScale, int offsetX, int offsetY, int supersample) {
    int renderSize = finalSize * Math.Max(1, supersample);
    using (var hi = new Bitmap(renderSize, renderSize, PixelFormat.Format32bppArgb)) {
      using (var g = Graphics.FromImage(hi)) {
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.CompositingQuality = CompositingQuality.HighQuality;
        g.Clear(Color.Transparent);
        using (var clip = new GraphicsPath()) {
          int iconSize = (int)Math.Round(renderSize * iconScale);
          int dx = (renderSize - iconSize) / 2 + (int)Math.Round(offsetX * (renderSize / 1024.0));
          int dy = (renderSize - iconSize) / 2 + (int)Math.Round(offsetY * (renderSize / 1024.0));
          clip.AddEllipse(dx, dy, iconSize, iconSize);
          g.SetClip(clip);
          g.DrawImage(src, new Rectangle(dx, dy, iconSize, iconSize), new Rectangle(cropX, cropY, cropSize, cropSize), GraphicsUnit.Pixel);
          g.ResetClip();
        }
      }

      using (var lo = new Bitmap(finalSize, finalSize, PixelFormat.Format32bppArgb)) {
        using (var g = Graphics.FromImage(lo)) {
          g.SmoothingMode = SmoothingMode.AntiAlias;
          g.InterpolationMode = InterpolationMode.HighQualityBicubic;
          g.PixelOffsetMode = PixelOffsetMode.HighQuality;
          g.CompositingQuality = CompositingQuality.HighQuality;
          g.Clear(Color.Transparent);
          g.DrawImage(hi, new Rectangle(0, 0, finalSize, finalSize));
        }
        lo.Save(path, ImageFormat.Png);
      }
    }
  }

  static void SaveIco(string path, List<Tuple<int, byte[]>> pngs) {
    Directory.CreateDirectory(Path.GetDirectoryName(path));
    using (var fs = File.Create(path))
    using (var bw = new BinaryWriter(fs)) {
      bw.Write((ushort)0);
      bw.Write((ushort)1);
      bw.Write((ushort)pngs.Count);
      uint offset = (uint)(6 + 16 * pngs.Count);
      foreach (var item in pngs) {
        int size = item.Item1;
        byte[] bytes = item.Item2;
        bw.Write((byte)(size == 256 ? 0 : size));
        bw.Write((byte)(size == 256 ? 0 : size));
        bw.Write((byte)0);
        bw.Write((byte)0);
        bw.Write((ushort)1);
        bw.Write((ushort)32);
        bw.Write((uint)bytes.Length);
        bw.Write(offset);
        offset += (uint)bytes.Length;
      }
      foreach (var item in pngs) bw.Write(item.Item2);
    }
  }
}
'@

Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition $Code -ReferencedAssemblies System.Drawing
[AppIconMaker]::Make($Root, $SourceImage, $CropX, $CropY, $CropSize, $IconScale, $OffsetX, $OffsetY, $Supersample)

Get-Item `
  (Join-Path $Root "assets\images\brand_mark.png"), `
  (Join-Path $Root "assets\images\app_icon.png"), `
  (Join-Path $Root "app_icon.ico"), `
  (Join-Path $Root "windows\runner\resources\app_icon.ico"), `
  (Join-Path $Root "desktop_lyric\windows\runner\resources\app_icon.ico") |
  Select-Object FullName, Length
