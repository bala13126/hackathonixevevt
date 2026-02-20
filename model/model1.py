import speech_recognition as sr
import pyttsx3
import json
from datetime import datetime
from googletrans import Translator

# Initialize translator
translator = Translator()

# Initialize speech engine
engine = pyttsx3.init()
engine.setProperty('rate', 170)

# --------------------------
# Select Language
# --------------------------
def select_language():
    print("Select Language:")
    print("1. English")
    print("2. Hindi")
    print("3. Tamil")
    print("4. Telugu")
    print("5. Malayalam")
    print("6. Kannada")

    choice = input("Enter choice number: ")

    languages = {
        "1": "en",
        "2": "hi",
        "3": "ta",
        "4": "te",
        "5": "ml",
        "6": "kn"
    }

    return languages.get(choice, "en")

# determine selected language (used for recognition and translation)
LANG = select_language()

# list of all supported language codes (used when speaking)
LANGUAGES = ["en", "hi", "ta", "te", "ml", "kn"]

# --------------------------
# Text to Speech
# --------------------------
def speak(text):
    # translate and speak the same response in every supported language
    for code in LANGUAGES:
        translated_text = translator.translate(text, dest=code).text
        print(f"Assistant ({code}):", translated_text)
        engine.say(translated_text)
    engine.runAndWait()

# --------------------------
# Speech to Text
# --------------------------
def listen():
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        print("\nListening...")
        recognizer.adjust_for_ambient_noise(source)
        audio = recognizer.listen(source)

    try:
        text = recognizer.recognize_google(audio, language=LANG)
        print("You:", text)
        return text
    except:
        speak("Sorry, I did not understand. Please repeat.")
        return listen()

# --------------------------
# Query Answering
# --------------------------
def answer_query(text):
    text_en = translator.translate(text, dest="en").text.lower()

    if "hello" in text_en:
        return "Hello! How can I help you?"
    elif "time" in text_en:
        return f"The current time is {datetime.now().strftime('%H:%M')}"
    elif "help" in text_en:
        return "Say report issue to start complaint registration."
    else:
        return "I am not sure about that. Say report issue to file a complaint."

# --------------------------
# Reporting System
# --------------------------
def collect_report():
    report = {}

    speak("Let's start your report.")

    speak("Please tell me your full name.")
    report["name"] = listen()

    speak("Please tell me the location of the issue.")
    report["location"] = listen()

    speak("What type of issue are you reporting?")
    report["issue_type"] = listen()

    speak("Please describe the issue in detail.")
    report["description"] = listen()

    # Validate missing info
    for key, value in report.items():
        if not value.strip():
            speak(f"I did not get your {key}. Please repeat.")
            report[key] = listen()

    report["timestamp"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with open("reports.json", "a", encoding="utf-8") as f:
        f.write(json.dumps(report, ensure_ascii=False) + "\n")

    speak("Your report has been submitted successfully.")
    print("\nFinal Structured Report:")
    print(json.dumps(report, indent=4, ensure_ascii=False))

# --------------------------
# Main Assistant Loop
# --------------------------
def main():
    speak("Voice assistant started. Say report issue to begin.")

    while True:
        text = listen()

        text_en = translator.translate(text, dest="en").text.lower()

        if "exit" in text_en or "stop" in text_en:
            speak("Goodbye!")
            break

        elif "report issue" in text_en:
            collect_report()

        else:
            response = answer_query(text)
            speak(response)


if __name__ == "__main__":
    main()