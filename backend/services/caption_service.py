class CaptionService:
    @staticmethod
    def get_caption_for_emotion(emotion: str) -> str:
        captions = {
            'relax': "Your dog looks relaxed and content!",
            'happy': "Your dog is happy and playful!",
            'angry': "Your dog seems a bit upset. Give them some space.",
            'frown': "Your dog looks a little sad. Maybe some cuddles?",
            'alert': "Your dog is alert and attentive!"
        }
        return captions.get(emotion, "Your dog's mood is detected!")
        
    @staticmethod
    def get_summary_caption(final_emotion: str, transitions: list, first_emotion: str = None, last_emotion: str = None):
        emotion_descriptions = {
            'relax': "relaxed and content",
            'happy': "happy and playful",
            'angry': "a bit upset. Give them some space",
            'frown': "a little sad. Maybe some cuddles?",
            'alert': "alert and attentive"
        }
        
        if not transitions:
            desc = emotion_descriptions.get(final_emotion, final_emotion)
            caption = f"Your dog was {desc} throughout the video!"
            timeline_summary = f"Mood: {final_emotion} throughout."
        else:
            first_desc = emotion_descriptions.get(first_emotion, first_emotion)
            last_desc = emotion_descriptions.get(last_emotion, last_emotion)
            caption = (
                f"Your dog started out {first_desc} and ended up {last_desc}. "
                f"Watch for changes in their mood!"
            )
            transition_str = ", ".join([f"{a}→{b}" for a, b in transitions])
            timeline_summary = f"Started: {first_emotion}, Ended: {last_emotion}, Transitions: {transition_str}"
            
        return caption, timeline_summary
