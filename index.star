load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("schema.star", "schema")
load("encoding/json.star", "json")

FOOTBALL_URL = "http://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard"
BASEBALL_URL = "http://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard"

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

NFL_TEAMS = {
  "Arizona Cardinals": "22",
  "Atlanta Falcons": "1",
  "Baltimore Ravens": "33",
  "Buffalo Bills": "2",
  "Carolina Panthers": "29",
  "Chicago Bears": "3",
  "Cincinnati Bengals": "4",
  "Cleveland Browns": "5",
  "Dallas Cowboys": "6",
  "Denver Broncos": "7",
  "Detroit Lions": "8",
  "Green Bay Packers": "9",
  "Houston Texans": "34",
  "Indianapolis Colts": "11",
  "Jacksonville Jaguars": "30",
  "Kansas City Chiefs": "12",
  "Las Vegas Raiders": "13",
  "Los Angeles Chargers": "24",
  "Los Angeles Rams": "14",
  "Miami Dolphins": "15",
  "Minnesota Vikings": "16",
  "New England Patriots": "17",
  "New Orleans Saints": "18",
  "New York Giants": "19",
  "New York Jets": "20",
  "Philadelphia Eagles": "21",
  "Pittsburgh Steelers": "23",
  "San Francisco 49ers": "25",
  "Seattle Seahawks": "26",
  "Tampa Bay Buccaneers": "27",
  "Tennessee Titans": "10",
  "Washington Commanders": "28"
}

MLB_TEAMS = {
    "Arizona Diamondbacks": "29",
    "Atlanta Braves": "15",
    "Baltimore Orioles": "1",
    "Boston Red Sox": "2",
    "Chicago Cubs": "16",
    "Chicago White Sox": "4",
    "Cincinnati Reds": "17",
    "Cleveland Guardians": "5",
    "Colorado Rockies": "27",
    "Detroit Tigers": "6",
    "Houston Astros": "18",
    "Kansas City Royals": "7",
    "Los Angeles Angels": "3",
    "Los Angeles Dodgers": "19",
    "Miami Marlins": "28",
    "Milwaukee Brewers": "8",
    "Minnesota Twins": "9",
    "New York Mets": "21",
    "New York Yankees": "10",
    "Oakland Athletics": "11",
    "Philadelphia Phillies": "22",
    "Pittsburgh Pirates": "23",
    "San Diego Padres": "25",
    "San Francisco Giants": "26",
    "Seattle Mariners": "12",
    "St. Louis Cardinals": "24",
    "Tampa Bay Rays": "30",
    "Texas Rangers": "13",
    "Toronto Blue Jays": "14",
    "Washington Nationals": "20",
}

def get_events_with_competitor(all_events, id):
    events_with_competitor = []
    for event in all_events:
        for competition in event["competitions"]:
            for competitor in competition["competitors"]:
                if competitor["id"] == id: #and not event["status"]["type"]["completed"]:
                    events_with_competitor.append(event)
    return events_with_competitor

def render_event_status(event, timezone):
    if event["status"]["type"]["name"] == "STATUS_SCHEDULED":
        return [
            render.Text(
                height=6,
                font="tom-thumb",
                content=time.parse_time(event["date"].replace("Z", ":00Z")).in_location(timezone).format("1/2  3:04 PM"),
                color="#ffffe0",
                offset=-1
            )
        ]
    else:
        return [
            render.Text(
                height=6,
                color="#fffff0",
                font="tom-thumb",
                content=event["status"]["type"]["shortDetail"],
                offset=-1
            )
        ]
       


def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]

    my_nfl_teams = []
    for team in NFL_TEAMS.keys():
        if (config.bool(team)):
            my_nfl_teams.append(team)

    my_mlb_teams = []
    for team in MLB_TEAMS.keys():
        if (config.bool(team)):
            my_mlb_teams.append(team)
   
    rep = http.get(FOOTBALL_URL, ttl_seconds = 60)
    if rep.status_code != 200:
        fail("Football request failed with status %d", rep.status_code)

    if not rep or not rep.json():
        my_nfl_events = []
    else:
        nfl_events = rep.json()["events"]
        my_nfl_events = []
        for team in my_nfl_teams:
            my_nfl_events = my_nfl_events + get_events_with_competitor(nfl_events, NFL_TEAMS[team])

    rep = http.get(BASEBALL_URL, ttl_seconds = 60)
    if rep.status_code != 200:
        fail("Baseball request failed with status %d", rep.status_code)

    if not rep or not rep.json():
        my_mlb_events = []
    else:
        mlb_events = rep.json()["events"]
        my_mlb_events = []
        for team in my_mlb_teams:
            my_mlb_events = my_mlb_events + get_events_with_competitor(mlb_events, MLB_TEAMS[team])

    my_events = my_nfl_events + my_mlb_events

    rows = []
    for event in my_events:
        rows.append(render.Row(
                main_align="start",
                cross_align="start",
                children=render_event_status(event, timezone)
        ))
        rows.append(render.Row(
            children=[
                render.Box(
                    child=render.Text(
                        font="5x8",
                        content=event["competitions"][0]["competitors"][1]["team"]["abbreviation"],
                        color=event["competitions"][0]["competitors"][1]["team"]["alternateColor"]
                    ),
                    height=10,
                    width=18,
                    color=event["competitions"][0]["competitors"][1]["team"]["color"]
                ),
                render.Box(
                    child=render.Text(
                        content=event["competitions"][0]["competitors"][1]["score"],
                        color=event["competitions"][0]["competitors"][1]["team"]["color"],
                        font="5x8",
                    ),
                    height=10,
                    width=14,
                    color=event["competitions"][0]["competitors"][1]["team"]["alternateColor"]
                ),
                render.Box(
                    child=render.Text(
                        font="5x8",
                        content=event["competitions"][0]["competitors"][0]["team"]["abbreviation"],
                        color=event["competitions"][0]["competitors"][0]["team"]["alternateColor"]
                    ),
                    height=10,
                    width=18,
                    color=event["competitions"][0]["competitors"][0]["team"]["color"]
                ),
                render.Box(
                    child=render.Text(
                       content=event["competitions"][0]["competitors"][0]["score"],
                       color=event["competitions"][0]["competitors"][0]["team"]["color"],
                       font="5x8",
                    ),
                    height=10,
                    width=14,
                    color=event["competitions"][0]["competitors"][0]["team"]["alternateColor"]
                ),
            ]
        ))
    
    if (len(rows) == 0):
        return render.Root(
            render.Box(
                render.WrappedText("[No Games Today]")
            )
        )

    return render.Root(
        delay=350,
        child=render.Marquee(
            child=render.Column(
                children=rows,
                cross_align="start",
                main_align="start"
            ),
            scroll_direction="vertical",
            height=32
        )
    )

def get_schema():
    nfl_options = [
        schema.Toggle(
            id = team,
            name = team,
            desc = "NFL - " + team,
            icon = "football",
            default = False,
        ) for team in NFL_TEAMS.keys()
    ]
    mlb_options = [
        schema.Toggle(
            id = team,
            name = team,
            desc = "MLB - " + team,
            icon = "baseball",
            default = False,
        ) for team in MLB_TEAMS.keys()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for diplaying local game times.",
                icon = "locationDot",
            )
        ] + nfl_options + mlb_options
    )
