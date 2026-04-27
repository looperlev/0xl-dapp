const DEFAULT_MAINNET_HTTPS = "https://api.mainnet-beta.solana.com";

/**
 * Returns a valid Solana JSON-RPC URL for browser requests.
 * Empty or malformed env values fall back to the public mainnet endpoint.
 */
export function getSolanaRpcUrl(): string {
  const raw = import.meta.env.VITE_SOLANA_RPC_URL;
  if (raw === undefined || raw === null) return DEFAULT_MAINNET_HTTPS;

  const url = String(raw).trim();
  if (url.length === 0) return DEFAULT_MAINNET_HTTPS;
  if (url.startsWith("http://") || url.startsWith("https://")) return url;

  return DEFAULT_MAINNET_HTTPS;
}
