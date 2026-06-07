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
        g.SmoothingMode = SmoothingMode.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.CompositingQuality = CompositingQuality.HighQuality;
        g.Clear(Color.Transparent);
        
        int iconSize = (int)Math.Round(renderSize * iconScale);
        int dx = (renderSize - iconSize) / 2 + (int)Math.Round(offsetX * (renderSize / 1024.0));
        int dy = (renderSize - iconSize) / 2 + (int)Math.Round(offsetY * (renderSize / 1024.0));
        
        // 绘制源图片到临时位图
        using (var tempBitmap = new Bitmap(iconSize, iconSize, PixelFormat.Format32bppArgb)) {
          using (var tg = Graphics.FromImage(tempBitmap)) {
            tg.SmoothingMode = SmoothingMode.HighQuality;
            tg.InterpolationMode = InterpolationMode.HighQualityBicubic;
            tg.PixelOffsetMode = PixelOffsetMode.HighQuality;
            tg.CompositingQuality = CompositingQuality.HighQuality;
            tg.Clear(Color.Transparent);
            tg.DrawImage(src, new Rectangle(0, 0, iconSize, iconSize), new Rectangle(cropX, cropY, cropSize, cropSize), GraphicsUnit.Pixel);
          }
          
          // 从角落采样背景色并去除
          var bg = tempBitmap.GetPixel(0, 0);
          int bgR = bg.R, bgG = bg.G, bgB = bg.B;
          int threshold = 30;
          
          for (int y = 0; y < iconSize; y++) {
            for (int x = 0; x < iconSize; x++) {
              var pixel = tempBitmap.GetPixel(x, y);
              int dr = Math.Abs(pixel.R - bgR);
              int dg = Math.Abs(pixel.G - bgG);
              int db = Math.Abs(pixel.B - bgB);
              if (dr < threshold && dg < threshold && db < threshold) {
                tempBitmap.SetPixel(x, y, Color.FromArgb(0, pixel.R, pixel.G, pixel.B));
              }
            }
          }
          
          // 创建圆形蒙版
          using (var maskBitmap = new Bitmap(iconSize, iconSize, PixelFormat.Format32bppArgb)) {
            using (var mg = Graphics.FromImage(maskBitmap)) {
              mg.SmoothingMode = SmoothingMode.HighQuality;
              mg.Clear(Color.Transparent);
              using (var brush = new SolidBrush(Color.White)) {
                mg.FillEllipse(brush, 1, 1, iconSize - 3, iconSize - 3);
              }
            }
            
            // 应用圆形蒙版
            for (int y = 0; y < iconSize; y++) {
              for (int x = 0; x < iconSize; x++) {
                var maskPixel = maskBitmap.GetPixel(x, y);
                var srcPixel = tempBitmap.GetPixel(x, y);
                int alpha = (srcPixel.A * maskPixel.A) / 255;
                tempBitmap.SetPixel(x, y, Color.FromArgb(alpha, srcPixel.R, srcPixel.G, srcPixel.B));
              }
            }
            
            g.DrawImage(tempBitmap, dx, dy, iconSize, iconSize);
          }
        }
      }

      using (var lo = new Bitmap(finalSize, finalSize, PixelFormat.Format32bppArgb)) {
        using (var g = Graphics.FromImage(lo)) {
          g.SmoothingMode = SmoothingMode.HighQuality;
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
