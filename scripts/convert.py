# Python script that will convert any text to HTML entities automatically
# https://emailsecurity.checkpoint.com/blog/phishing-trend-targeting-office-365-uses-html-attachments

def text_to_html_entities(text):
    # Convert each character to its HTML entity representation
    return ''.join(f'&#{ord(c)};' for c in text)

# Example usage
if __name__ == "__main__":
    # Take input text from the user
    input_text = input("Enter the text you want to convert to HTML entities: ")

    # Convert to HTML entities
    converted_text = text_to_html_entities(input_text)

    # Display the result
    print("Converted HTML entities:")
    print(converted_text)

