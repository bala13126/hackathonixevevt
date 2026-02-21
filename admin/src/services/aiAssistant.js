import { supabase } from './supabaseClient';

// Sends a prompt to a Supabase Edge Function named 'ai-assistant'
// The Edge Function should handle calls to your AI provider (OpenAI, etc.)
// and return { text: string, data?: any }.

export async function askAssistant(prompt, opts = {}) {
  if (!prompt) throw new Error('Prompt is required');

  // Use Supabase Functions (Edge Functions)
  try {
    const resp = await supabase.functions.invoke('ai-assistant', {
      body: JSON.stringify({ prompt, options: opts }),
    });

    if (resp.error) throw resp.error;
    // resp.data is a Uint8Array when using functions.invoke; try to parse
    let text = null;
    try {
      const decoder = new TextDecoder();
      const json = decoder.decode(resp.data);
      const parsed = JSON.parse(json);
      text = parsed.text ?? parsed;
      return parsed;
    } catch (e) {
      // fallback: return raw
      return resp;
    }
  } catch (err) {
    throw err;
  }
}
