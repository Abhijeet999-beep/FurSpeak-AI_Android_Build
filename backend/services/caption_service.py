import random

class CaptionService:
    # A dictionary mapping emotions to lists of caption variations.
    # This structure is highly scalable and easy to extend with new variations or emotions.
    EMOTION_CAPTIONS = {
        'relax': [
            "Your dog looks relaxed and content!",
            "Your pup is in full chill mode, completely at ease.",
            "Looks like someone is enjoying a peaceful moment!",
            "Feeling calm, serene, and absolutely relaxed.",
            "Pure tranquility! Your dog is perfectly content right now."
        ],
        'happy': [
            "Your dog is happy and playful!",
            "Look at that tail wag! Someone's having a wonderful day!",
            "Your pup is bursting with joy and ready for some fun!",
            "Pure happiness! Life is good when you're this joyful.",
            "Such a happy face! Your dog is feeling absolutely great!"
        ],
        'angry': [
            "Your dog seems a bit upset. Give them some space.",
            "Your dog is showing signs of irritation. Best to step back.",
            "A bit grumpy or tense right now. Let's give them some quiet time.",
            "Looks like someone needs a little peace and quiet. Give them space.",
            "Your pup is feeling defensive or annoyed. Let them calm down."
        ],
        'frown': [
            "Your dog looks a little sad. Maybe some cuddles?",
            "A bit down or lonely. Time for some extra love and attention!",
            "Those puppy dog eyes... looks like someone could use a treat or a hug.",
            "Your dog seems a little blue. A gentle pat might cheer them up!",
            "Feeling a bit low. Show them some extra warmth and comfort."
        ],
        'alert': [
            "Your dog is alert and attentive!",
            "On duty! Your pup is scanning the area and paying close attention.",
            "Super focused! Something has definitely caught your dog's interest.",
            "Ears up, eyes forward—your dog is highly alert and engaged.",
            "Very observant! Your dog is tuned in and watching closely."
        ]
    }

    # Descriptions used in video summaries
    EMOTION_DESCRIPTIONS = {
        'relax': ["relaxed and content", "calm and peaceful", "chilled out"],
        'happy': ["happy and playful", "joyful and excited", "cheerful and energetic"],
        'angry': ["a bit upset", "showing signs of irritation", "grumpy and tense"],
        'frown': ["a little sad", "somewhat lonely", "a bit blue"],
        'alert': ["alert and attentive", "highly focused", "observant and watchful"]
    }

    @staticmethod
    def get_caption_for_emotion(emotion: str) -> str:
        emotion_key = emotion.lower().strip()
        variations = CaptionService.EMOTION_CAPTIONS.get(emotion_key)
        if variations:
            return random.choice(variations)
        return "Your dog's mood is detected!"
        
    @staticmethod
    def get_summary_caption(final_emotion: str, transitions: list, first_emotion: str = None, last_emotion: str = None):
        final_key = final_emotion.lower().strip()
        first_key = first_emotion.lower().strip() if first_emotion else None
        last_key = last_emotion.lower().strip() if last_emotion else None

        def get_desc(emo):
            descs = CaptionService.EMOTION_DESCRIPTIONS.get(emo)
            return random.choice(descs) if descs else emo

        if not transitions:
            desc = get_desc(final_key)
            templates = [
                f"Your dog was {desc} throughout the video!",
                f"Throughout the video, your pup stayed {desc}.",
                f"We observed your dog looking {desc} for the entire duration."
            ]
            caption = random.choice(templates)
            timeline_summary = f"Mood: {final_emotion} throughout."
        else:
            first_desc = get_desc(first_key)
            last_desc = get_desc(last_key)
            templates = [
                f"Your dog started out {first_desc} and ended up {last_desc}. Watch for changes in their mood!",
                f"We noticed a shift: starting {first_desc} and transitioning to {last_desc} by the end.",
                f"Your pup went from being {first_desc} to {last_desc}. Keep an eye on their emotional transitions!"
            ]
            caption = random.choice(templates)
            transition_str = ", ".join([f"{a}→{b}" for a, b in transitions])
            timeline_summary = f"Started: {first_emotion}, Ended: {last_emotion}, Transitions: {transition_str}"
            
        return caption, timeline_summary
