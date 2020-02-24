import
  tables,
  sequtils,
  sets,
  ./entity,
  ./component

type CompGroup* = CompClass

type EcTable* = TableRef[Entity, Component] ## Entity-component table
type CompTable* = array[CompGroup, Component] ## Component table (grouped)

type Registry* = ref object
  ## Entity-component registry.
  data*: TableRef[Entity, CompTable]
  dataGrouped*: array[CompGroup, EcTable]
  nextEntity: Entity ## Used to create unique entities

proc newRegistry*(): Registry =
  new result

  result.data = newTable[Entity, CompTable]()

  for group in result.dataGrouped.mitems():
    group = newTable[Entity, Component]()

  result.nextEntity = 0

proc createEntity*(reg: Registry): Entity =
  result = reg.nextEntity
  # TODO: Figure out how to initialize empty value
  var compTable: CompTable
  reg.data[result] = compTable
  reg.nextEntity.inc()

proc assignComponent*(
  reg: Registry,
  entity: Entity,
  group: CompGroup,
  component: Component
) =
  reg.dataGrouped[group][entity] = component
  reg.data[entity][group] = component

proc assignComponent*[T](
  reg: Registry,
  entity: Entity,
  component: T
) =
  let group = component.getClass()
  reg.assignComponent(entity, group, component)

proc entitiesOfClass*(
  reg: Registry,
  class: CompClass
): HashSet[Entity] =
  ## Get entities that have components of `class`
  for k in reg.dataGrouped[class].keys():
    result.incl(k)

proc entitiesOfClasses*(
  reg: Registry,
  classes: varargs[CompClass]
): HashSet[Entity] =
  ## Get entities that have components of all `classes`
  result = reg.entitiesOfClass(classes[0])
  for i in 1 ..< classes.len:
    let matches = reg.entitiesOfClass(classes[i])
    result = intersection(result, matches)

proc componentsOfEntity*(
  reg: Registry,
  entity: Entity
): CompTable =
  ## Get components belonging to `entity`
  reg.data[entity]

proc componentOfEntity*(
  reg: Registry,
  entity: Entity,
  class: CompClass
): Component =
  ## Get component of `class` belonging to `entity`
  reg.data[entity][class]

proc removeComponent*(
  reg: Registry,
  entity: Entity,
  class: CompClass
) =
  ## Remove component of `class` belonging to `entity`
  reg.data[entity][class] = nil
  reg.dataGrouped[class].del(entity)
