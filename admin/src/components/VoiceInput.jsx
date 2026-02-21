import React, { useEffect, useRef, useState } from 'react';

// Simple Voice Input using Web Speech API (SpeechRecognition)
// Props:
// - onResult(text): called when interim/final transcript available
// - continuous: boolean
// - lang: language code (default 'en-US')

const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition || null;

export default function VoiceInput({ onResult, continuous = false, lang = 'en-US' }) {
  const [listening, setListening] = useState(false);
  const recognitionRef = useRef(null);

  useEffect(() => {
    if (!SpeechRecognition) return;
    const recognition = new SpeechRecognition();
    recognition.lang = lang;
    recognition.interimResults = true;
    recognition.continuous = continuous;

    recognition.onresult = (event) => {
      let interim = '';
      let final = '';
      for (let i = event.resultIndex; i < event.results.length; ++i) {
        const res = event.results[i];
        if (res.isFinal) final += res[0].transcript;
        else interim += res[0].transcript;
      }
      if (onResult) onResult({ interim, final });
    };

    recognition.onerror = (e) => {
      console.error('Speech recognition error', e);
    };

    recognitionRef.current = recognition;
    return () => {
      recognition.stop();
      recognitionRef.current = null;
    };
  }, [lang, continuous, onResult]);

  const start = () => {
    if (!recognitionRef.current) return;
    try {
      recognitionRef.current.start();
      setListening(true);
    } catch (e) {
      // already started
    }
  };

  const stop = () => {
    if (!recognitionRef.current) return;
    recognitionRef.current.stop();
    setListening(false);
  };

  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
      <button type="button" onClick={start} disabled={!SpeechRecognition || listening}>
        Start
      </button>
      <button type="button" onClick={stop} disabled={!SpeechRecognition || !listening}>
        Stop
      </button>
      {!SpeechRecognition && <div style={{ color: 'crimson' }}>Voice not supported</div>}
    </div>
  );
}
