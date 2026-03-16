#!/usr/bin/env python3
"""Generate edge/border overlay PNG images for Lumé photo editor."""

from PIL import Image, ImageDraw
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'Fotico', 'Resources', 'Edges')
os.makedirs(OUTPUT_DIR, exist_ok=True)

WIDTH, HEIGHT = 1200, 1600

def generate_polaroid_border():
    """White Polaroid-style border with larger bottom."""
    img = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    border = 40
    bottom_border = 120
    # White border frame
    draw.rectangle([0, 0, WIDTH, HEIGHT], fill=(255, 255, 255, 255))
    # Transparent inner area
    draw.rectangle([border, border, WIDTH - border, HEIGHT - bottom_border], fill=(0, 0, 0, 0))
    img.save(os.path.join(OUTPUT_DIR, 'edge_polaroid_border.png'))
    print('Generated edge_polaroid_border.png')

def generate_35mm_border():
    """Film strip border with sprocket holes."""
    img = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    border = 50
    # Black border
    draw.rectangle([0, 0, WIDTH, HEIGHT], fill=(20, 20, 20, 255))
    # Transparent inner
    draw.rectangle([border, border, WIDTH - border, HEIGHT - border], fill=(0, 0, 0, 0))
    # Sprocket holes on left and right
    hole_w, hole_h = 16, 24
    for y in range(30, HEIGHT, 60):
        # Left holes
        draw.rounded_rectangle([10, y, 10 + hole_w, y + hole_h], radius=4, fill=(0, 0, 0, 0))
        # Right holes
        draw.rounded_rectangle([WIDTH - 10 - hole_w, y, WIDTH - 10, y + hole_h], radius=4, fill=(0, 0, 0, 0))
    img.save(os.path.join(OUTPUT_DIR, 'edge_35mm_border.png'))
    print('Generated edge_35mm_border.png')

def generate_inset_border():
    """Thin white inset border with rounded corners."""
    img = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    margin = 30
    thickness = 3
    # Draw thin white rectangle outline
    draw.rounded_rectangle(
        [margin, margin, WIDTH - margin, HEIGHT - margin],
        radius=8,
        outline=(255, 255, 255, 200),
        width=thickness
    )
    img.save(os.path.join(OUTPUT_DIR, 'edge_inset.png'))
    print('Generated edge_inset.png')

def generate_round_border():
    """Soft vignette-style dark rounded border."""
    img = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Create black frame with large rounded rectangle cutout
    draw.rectangle([0, 0, WIDTH, HEIGHT], fill=(0, 0, 0, 220))
    # Cut out rounded inner area
    margin = 24
    draw.rounded_rectangle(
        [margin, margin, WIDTH - margin, HEIGHT - margin],
        radius=40,
        fill=(0, 0, 0, 0)
    )
    img.save(os.path.join(OUTPUT_DIR, 'edge_round.png'))
    print('Generated edge_round.png')

if __name__ == '__main__':
    generate_polaroid_border()
    generate_35mm_border()
    generate_inset_border()
    generate_round_border()
    print(f'All edges saved to {OUTPUT_DIR}')
