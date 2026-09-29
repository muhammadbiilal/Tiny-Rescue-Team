import 'package:tiny_rescue_team/simulation/roles.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';

/// Small authoring DSL so scenes read like level scripts.
class SceneBuilder {
  final String id;
  final int world, slot;
  String title = '';
  String brief = '';
  List<String> tutorial = [];
  List<String> strategies = [];
  int teamSize = 2;
  List<Role> roles = [];
  List<Gear> gear = [];
  Rules rules = const Rules();
  final List<SceneNode> nodes = [];
  final List<SceneEdge> edges = [];
  final List<DeployZone> deploy = [];
  final List<Civilian> civilians = [];
  final List<Shelter> shelters = [];
  final List<Depot> depots = [];
  final List<Need> needs = [];
  final List<Fire> fires = [];
  final List<HazardEvent> hazards = [];
  final List<Objective> objectives = [];
  final List<String> decor = [];
  String authoring = 'hand';

  SceneBuilder(this.id, this.world, this.slot);

  String node(
    String id,
    int x,
    int y, [
    String label = '',
    NodeKind kind = NodeKind.street,
  ]) {
    nodes.add(SceneNode(id, x, y, kind: kind, label: label));
    return id;
  }

  String start(String id, int x, int y, String label, {int capacity = 1}) {
    node(id, x, y, label, NodeKind.deploy);
    deploy.add(DeployZone(id, capacity: capacity));
    return id;
  }

  String shelter(
    String id,
    int x,
    int y,
    String label, {
    int capacity = 0,
    int openAt = 0,
    bool broken = false,
  }) {
    node(id, x, y, label, NodeKind.shelter);
    shelters.add(
      Shelter(id, capacity: capacity, openAt: openAt, broken: broken),
    );
    return id;
  }

  String depot(String id, int x, int y, String label, int stock) {
    node(id, x, y, label, NodeKind.depot);
    depots.add(Depot(id, stock));
    return id;
  }

  String need(String id, int x, int y, String label, int count) {
    node(id, x, y, label, NodeKind.need);
    needs.add(Need('need_$id', id, count));
    return 'need_$id';
  }

  String lane(
    String a,
    String b, [
    String label = '',
    Block block = Block.none,
    Terrain terrain = Terrain.road,
    String? link,
  ]) {
    final id = '$a-$b';
    edges.add(
      SceneEdge(
        id,
        a,
        b,
        label: label,
        block: block,
        terrain: terrain,
        link: link,
      ),
    );
    return id;
  }

  String person(
    String node, {
    bool care = false,
    bool critical = false,
    bool hidden = false,
  }) {
    final id = 'c${civilians.length + 1}';
    civilians.add(
      Civilian(
        id,
        node,
        needsCare: care,
        critical: critical,
        hidden: hidden,
        look: civilians.length % 4,
      ),
    );
    return id;
  }

  void fire(String node, [int intensity = 1]) =>
      fires.add(Fire(node, intensity));

  void goal(
    ObjectiveType t, {
    int count = 0,
    String? target,
    String? a,
    String? b,
    List<String> nodes = const [],
    int by = 0,
  }) => objectives.add(
    Objective(
      t,
      count: count,
      target: target,
      a: a,
      b: b,
      nodes: nodes,
      by: by,
    ),
  );

  MissionScene build({int revision = 1}) => MissionScene(
    id: id,
    revision: revision,
    world: world,
    slot: slot,
    title: title,
    brief: brief,
    tutorial: tutorial,
    strategies: strategies,
    teamSize: teamSize,
    allowedRoles: roles,
    gear: gear,
    nodes: nodes,
    edges: edges,
    deploy: deploy,
    civilians: civilians,
    shelters: shelters,
    depots: depots,
    needs: needs,
    fires: fires,
    hazards: hazards,
    objectives: objectives,
    rules: rules,
    decor: decor,
    review: Review(authoring: authoring),
  );
}
