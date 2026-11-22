"""Schneidet kurze Ausschnitte aus eigenen Videos als Einzelbilder (540×960) für das KI-Video."""
import os, shutil, subprocess
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, 'build', 'ki1', 'clips')
CLIPS = {  # Name: (Datei, Start, Dauer)
    'katze': ('katze7-synth.mp4', 0.4, 3.0), 'philo': ('philo1-chatterbox.mp4', 3.0, 1.2), 'hist': ('hist2-chatterbox.mp4', 44.0, 1.2),
    'hell': ('sk2-chatterbox.mp4', 6.5, 1.2), 'iw': ('iw1-chatterbox.mp4', 28.9, 1.2), 'quiz': ('quiz3-chatterbox.mp4', 10.0, 1.2),
    'emc': ('emc1-chatterbox.mp4', 41.0, 1.2), 'auto': ('auto1-chatterbox.mp4', 26.3, 4.0), 'autowide': ('auto1-chatterbox.mp4', 15.0, 6.0),
}
shutil.rmtree(OUT, ignore_errors=True)
for name, (f, s, d) in CLIPS.items():
    o = os.path.join(OUT, name); os.makedirs(o)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(s), '-t', str(d), '-i', os.path.join(HERE, 'out', f), '-vf', 'fps=30,scale=540:960',
                    '-q:v', '4', '-start_number', '0', os.path.join(o, 'f%04d.jpg')], check=True)
    print(name, len(os.listdir(o)))
