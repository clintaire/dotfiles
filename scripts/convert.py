"""
This script is provided for educational and informational purposes only.
Use of this script is at your own risk. The author assumes no liability for any
damages or legal consequences resulting from its use. Ensure you comply with
all applicable laws and regulations regarding data processing and privacy when
using this script.
"""

# Python script that will convert any text to HTML entities automatically


def text_to_html_entities(text):
    """
    Convert each character in the input text to its HTML entity representation.
    Args:
        text (str): The input string to convert.
    Returns:
        str: The converted string with HTML entities.
    """
    return ''.join(f'&#{ord(c)};' for c in text)


def main():
    print("HTML Entity Converter\n======================\n")
    input_text = input("Enter the text you want to convert to HTML entities: ")
    converted_text = text_to_html_entities(input_text)
    print("\nConverted HTML entities:\n")
    print(converted_text)


if __name__ == "__main__":
    main()
