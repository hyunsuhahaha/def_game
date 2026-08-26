param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath
)

Add-Type -AssemblyName System.Drawing
$runtimeDirectory = Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$drawingReferences = @(
    [System.Drawing.Bitmap].Assembly.Location,
    [System.Drawing.Rectangle].Assembly.Location,
    (Join-Path $runtimeDirectory "System.Private.Windows.Core.dll"),
    (Join-Path $runtimeDirectory "System.Private.Windows.GdiPlus.dll")
)
Add-Type -ReferencedAssemblies $drawingReferences -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CheckerboardAlpha
{
    public static void Extract(string inputPath, string outputPath)
    {
        using (var source = new Bitmap(inputPath))
        using (var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(bitmap))
                graphics.DrawImageUnscaled(source, 0, 0);

            var rect = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
            var bits = bitmap.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            var bytes = new byte[Math.Abs(bits.Stride) * bitmap.Height];
            Marshal.Copy(bits.Scan0, bytes, 0, bytes.Length);

            int width = bitmap.Width, height = bitmap.Height, stride = bits.Stride;
            var visited = new bool[width * height];
            var queue = new int[width * height];
            int queueHead = 0, queueTail = 0;

            Func<int, int, bool> isChecker = (x, y) => {
                int p = y * stride + x * 4;
                int b = bytes[p], g = bytes[p + 1], r = bytes[p + 2];
                int min = Math.Min(r, Math.Min(g, b));
                int max = Math.Max(r, Math.Max(g, b));
                return min >= 225 && max - min <= 14;
            };

            Action<int, int> enqueue = (x, y) => {
                int index = y * width + x;
                if (!visited[index] && isChecker(x, y)) {
                    visited[index] = true;
                    queue[queueTail++] = index;
                }
            };

            for (int x = 0; x < width; x++) { enqueue(x, 0); enqueue(x, height - 1); }
            for (int y = 0; y < height; y++) { enqueue(0, y); enqueue(width - 1, y); }

            while (queueHead < queueTail) {
                int index = queue[queueHead++];
                int x = index % width, y = index / width;
                int p = y * stride + x * 4;
                bytes[p] = bytes[p + 1] = bytes[p + 2] = bytes[p + 3] = 0;
                if (x > 0) enqueue(x - 1, y);
                if (x + 1 < width) enqueue(x + 1, y);
                if (y > 0) enqueue(x, y - 1);
                if (y + 1 < height) enqueue(x, y + 1);
            }

            // Checker tiles can be completely enclosed by branches. Clear those
            // exact near-neutral light pixels as well; colored sprite pixels stay.
            for (int y = 0; y < height; y++) {
                for (int x = 0; x < width; x++) {
                    if (!isChecker(x, y)) continue;
                    int p = y * stride + x * 4;
                    bytes[p] = bytes[p + 1] = bytes[p + 2] = bytes[p + 3] = 0;
                }
            }

            Marshal.Copy(bytes, 0, bits.Scan0, bytes.Length);
            bitmap.UnlockBits(bits);
            bitmap.Save(outputPath, ImageFormat.Png);
        }
    }
}
'@

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
[CheckerboardAlpha]::Extract($resolvedInput, $OutputPath)
