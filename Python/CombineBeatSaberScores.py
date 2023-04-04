import os
import json

def combine_scores(files):
    leaderboards_data = {"_leaderboardsData": []}
    score_dict = {}
    for filename in files:
        with open(filename) as f:
            data = json.load(f)
            for leaderboard in data["_leaderboardsData"]:
                leaderboard_id = leaderboard["_leaderboardId"]
                if leaderboard_id not in score_dict:
                    score_dict[leaderboard_id] = []
                for score in leaderboard["_scores"]:
                    if score["_score"] not in [entry["_score"] for entry in score_dict[leaderboard_id]]:
                        score["_leaderboardId"] = leaderboard_id  # add the correct ID
                        score_dict[leaderboard_id].append(score)

    for leaderboard_id, scores in score_dict.items():
        sorted_scores = sorted(scores, key=lambda x: x["_score"], reverse=True)[:10]
        leaderboards_data["_leaderboardsData"].append({
            "_leaderboardId": leaderboard_id,
            "_scores": sorted_scores
        })

    with open("LocalLeaderboards.dat", "w") as f:
        json.dump(leaderboards_data, f, indent=4)

def main():
    file_list = []
    for filename in os.listdir():
        if filename.endswith(".dat"):
            file_list.append(filename)
    combine_scores(file_list)

if __name__ == '__main__':
    main()
