using System;
using System.Collections;
using TMPro;
using UnityEngine;

namespace WoofTalk.VR.UI
{
    /// <summary>
    /// Manages a single translation bubble: text display, background visibility,
    /// auto-dismiss timer, and pool return signaling.
    /// </summary>
    public class TranslationBubble : MonoBehaviour
    {
        [SerializeField] private TMP_Text displayText;
        [SerializeField] private GameObject backgroundPanel;

        public event Action onPinned;
        public event Action poolReturn;

        public void SetText(string text)
        {
            if (displayText != null)
            {
                displayText.text = text;
            }
        }

        public void Dismiss()
        {
            if (poolReturn != null)
            {
                poolReturn.Invoke();
            }
        }

        public IEnumerator DismissAfter(float seconds)
        {
            yield return new WaitForSeconds(seconds);
            Dismiss();
        }

        public void OnPin()
        {
            if (onPinned != null)
            {
                onPinned.Invoke();
            }
        }

        void OnEnable()
        {
            if (backgroundPanel != null)
            {
                backgroundPanel.SetActive(true);
            }
        }

        void OnDisable()
        {
            if (displayText != null)
            {
                displayText.text = string.Empty;
            }
        }
    }
}
