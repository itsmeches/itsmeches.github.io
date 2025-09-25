let recognition;
let dartCallback;

function initSpeechRecognition(callback) {
  dartCallback = callback;

  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SpeechRecognition) {
    console.error("❌ SpeechRecognition not supported in this browser.");
    dartCallback("SpeechRecognition not supported", true);
    return;
  }

  recognition = new SpeechRecognition();
  recognition.lang = "en-US";
  recognition.continuous = false;
  recognition.interimResults = false;

  recognition.onresult = (event) => {
    const transcript = event.results[0][0].transcript;
    dartCallback(transcript, false);
  };

  recognition.onerror = (event) => {
    dartCallback(event.error, true);
  };
}

function startListening() {
  if (recognition) {
    recognition.start();
    console.log("🎤 Listening...");
  }
}

function stopListening() {
  if (recognition) {
    recognition.stop();
    console.log("🛑 Stopped listening.");
  }
}
