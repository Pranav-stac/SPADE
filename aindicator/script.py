from PIL import Image, ImageDraw, ImageFont

# Function to create a logo image with text
def create_logo(text, output_path):
    # Define the size of the image
    width = 256
    height = 256

    # Create a new image with a white background
    image = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(image)

    # Load a font
    try:
        font = ImageFont.truetype("arial.ttf", 48)
    except IOError:
        font = ImageFont.load_default()

    # Calculate text width and height to center it
    text_width, text_height = draw.textsize(text, font=font)
    text_x = (width - text_width) / 2
    text_y = (height - text_height) / 2

    # Draw the text on the image
    draw.text((text_x, text_y), text, font=font, fill='black')

    # Save the image
    image.save(output_path)

# Example usage
if __name__ == "__main__":
    create_logo('A-Indicator', 'assets/logo.png')