export async function dataUrlToBlob(dataUrl: string): Promise<Blob> {
  const [header, base64] = dataUrl.split(',');
  const mime = header.match(/^data:(.*?);/)?.[1] ?? 'application/octet-stream';
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return new Blob([bytes], { type: mime });
}
