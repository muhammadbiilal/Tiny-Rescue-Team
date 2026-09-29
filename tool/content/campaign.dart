import 'builder.dart';
import 'old_town_intro.dart';
import 'old_town_rest.dart';
import 'slice.dart';

/// Every hand-authored scene currently in the campaign, in mission order.
List<SceneBuilder> authoredCampaign() => [
  ...harborWorld(),
  ...oldTownIntro(),
  ...oldTownRest(),
];
