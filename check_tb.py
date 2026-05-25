import os
from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

log_dir = "logs/sb3"
experiments = ["experiment_10", "experiment_41"]
for exp in experiments:
    path = os.path.join(log_dir, exp)
    if not os.path.exists(path):
        continue
    event_acc = EventAccumulator(path)
    event_acc.Reload()
    print(f"--- {exp} ---")
    scalars = event_acc.Tags().get('scalars', [])
    print("Tags:", scalars)
    for tag in scalars:
        events = event_acc.Scalars(tag)
        if events:
            print(f"{tag}: last value = {events[-1].value}")
