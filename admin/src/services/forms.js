import { supabase } from './supabaseClient';

export async function saveCase(caseData) {
  const { data, error } = await supabase.from('cases').insert([caseData]).select().single();
  if (error) throw error;
  return data;
}

export async function updateCaseStatus(caseId, status) {
  const { data, error } = await supabase.from('cases').update({ status }).eq('id', caseId).select().single();
  if (error) throw error;
  return data;
}

export async function saveTip(tipData) {
  const { data, error } = await supabase.from('tips').insert([tipData]).select().single();
  if (error) throw error;
  return data;
}

export async function verifyTip(tipId) {
  const { data, error } = await supabase.from('tips').update({ verified: true }).eq('id', tipId).select().single();
  if (error) throw error;
  return data;
}
