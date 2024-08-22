// ### MATH ###

typedef struct b2Vec2
{
    float x, y;
} b2Vec2;

typedef struct b2Rot
{
    float c, s;
} b2Rot;

typedef struct b2Transform
{
    b2Vec2 p;
    b2Rot q;
} b2Transform;

typedef struct b2Mat22
{
    b2Vec2 cx, cy;
} b2Mat22;

typedef struct b2AABB
{
    b2Vec2 lowerBound;
    b2Vec2 upperBound;
} b2AABB;

// ### WORLD ###

typedef void b2TaskCallback( int32_t startIndex, int32_t endIndex, uint32_t workerIndex, void* taskContext );
typedef void* b2EnqueueTaskCallback( b2TaskCallback* task, int32_t itemCount, int32_t minRange, void* taskContext, void* userContext );
typedef void b2FinishTaskCallback( void* userTask, void* userContext );

typedef struct b2WorldDef
{
    b2Vec2 gravity;
    float restitutionThreshold;
    float contactPushoutVelocity;
    float hitEventThreshold;
    float contactHertz;
    float contactDampingRatio;
    float jointHertz;
    float jointDampingRatio;
    float maximumLinearVelocity;
    bool enableSleep;
    bool enableContinous;
    int32_t workerCount;
    b2EnqueueTaskCallback* enqueueTask;
    b2FinishTaskCallback* finishTask;
    void* userTaskContext;
    int32_t internalValue;
} b2WorldDef;

b2WorldDef b2DefaultWorldDef( void );

typedef struct b2WorldId
{
    uint16_t index1;
    uint16_t revision;
} b2WorldId;

b2WorldId b2CreateWorld( const b2WorldDef* def );
void b2DestroyWorld( b2WorldId worldId );
bool b2World_IsValid( b2WorldId id );
void b2World_Step( b2WorldId worldId, float timeStep, int subStepCount );
void b2World_SetGravity( b2WorldId worldId, b2Vec2 gravity );
b2Vec2 b2World_GetGravity( b2WorldId worldId );
void b2World_EnableSleeping( b2WorldId worldId, bool flag );
void b2World_EnableContinuous( b2WorldId worldId, bool flag );
void b2World_SetRestitutionThreshold( b2WorldId worldId, float value );
void b2World_SetHitEventThreshold( b2WorldId worldId, float value );

// ### BODY ###

typedef enum b2BodyType
{
    b2_staticBody = 0,
    b2_kinematicBody = 1,
    b2_dynamicBody = 2,
    b2_bodyTypeCount,
} b2BodyType;

typedef struct b2BodyDef
{
    b2BodyType type;
    b2Vec2 position;
    b2Rot rotation;
    b2Vec2 linearVelocity;
    float angularVelocity;
    float linearDamping;
    float angularDamping;
    float gravityScale;
    float sleepThreshold;
    void* userData;
    bool enableSleep;
    bool isAwake;
    bool fixedRotation;
    bool isBullet;
    bool isEnabled;
    bool automaticMass;
    bool allowFastRotation;
    int32_t internalValue;
} b2BodyDef;

typedef struct b2BodyId
{
    int32_t index1;
    uint16_t world0;
    uint16_t revision;
} b2BodyId;

b2BodyDef b2DefaultBodyDef( void );
b2BodyId b2CreateBody( b2WorldId worldId, const b2BodyDef* def );
void b2DestroyBody( b2BodyId bodyId );
bool b2Body_IsValid( b2BodyId id );
b2BodyType b2Body_GetType( b2BodyId bodyId );
void b2Body_SetType( b2BodyId bodyId, b2BodyType type );
b2Transform b2Body_GetTransform( b2BodyId bodyId );
void b2Body_SetTransform( b2BodyId bodyId, b2Vec2 position, b2Rot rotation );
b2Vec2 b2Body_GetLocalPoint( b2BodyId bodyId, b2Vec2 worldPoint );
b2Vec2 b2Body_GetWorldPoint( b2BodyId bodyId, b2Vec2 localPoint );
b2Vec2 b2Body_GetLocalVector( b2BodyId bodyId, b2Vec2 worldVector );
b2Vec2 b2Body_GetWorldVector( b2BodyId bodyId, b2Vec2 localVector );
b2Vec2 b2Body_GetLinearVelocity( b2BodyId bodyId );
float b2Body_GetAngularVelocity( b2BodyId bodyId );
void b2Body_SetLinearVelocity( b2BodyId bodyId, b2Vec2 linearVelocity );
void b2Body_SetAngularVelocity( b2BodyId bodyId, float angularVelocity );
void b2Body_ApplyForce( b2BodyId bodyId, b2Vec2 force, b2Vec2 point, bool wake );
void b2Body_ApplyForceToCenter( b2BodyId bodyId, b2Vec2 force, bool wake );
void b2Body_ApplyTorque( b2BodyId bodyId, float torque, bool wake );
void b2Body_ApplyLinearImpulse( b2BodyId bodyId, b2Vec2 impulse, b2Vec2 point, bool wake );
void b2Body_ApplyLinearImpulseToCenter( b2BodyId bodyId, b2Vec2 impulse, bool wake );
void b2Body_ApplyAngularImpulse( b2BodyId bodyId, float impulse, bool wake );
float b2Body_GetMass( b2BodyId bodyId );
float b2Body_GetInertiaTensor( b2BodyId bodyId );
b2Vec2 b2Body_GetLocalCenterOfMass( b2BodyId bodyId );
b2Vec2 b2Body_GetWorldCenterOfMass( b2BodyId bodyId );

typedef struct b2MassData
{
    float mass;
    b2Vec2 center;
    float rotationalInertia;
} b2MassData;

void b2Body_SetMassData( b2BodyId bodyId, b2MassData massData );
b2MassData b2Body_GetMassData( b2BodyId bodyId );
void b2Body_SetAutomaticMass( b2BodyId bodyId, bool automaticMass );
bool b2Body_GetAutomaticMass( b2BodyId bodyId );
void b2Body_SetLinearDamping( b2BodyId bodyId, float linearDamping );
float b2Body_GetLinearDamping( b2BodyId bodyId );
void b2Body_SetAngularDamping( b2BodyId bodyId, float angularDamping );
float b2Body_GetAngularDamping( b2BodyId bodyId );
void b2Body_SetGravityScale( b2BodyId bodyId, float gravityScale );
float b2Body_GetGravityScale( b2BodyId bodyId );
bool b2Body_IsAwake( b2BodyId bodyId );
void b2Body_SetAwake( b2BodyId bodyId, bool awake );
void b2Body_EnableSleep( b2BodyId bodyId, bool enableSleep );
bool b2Body_IsSleepEnabled( b2BodyId bodyId );
void b2Body_SetSleepThreshold( b2BodyId bodyId, float sleepVelocity );
float b2Body_GetSleepThreshold( b2BodyId bodyId );
bool b2Body_IsEnabled( b2BodyId bodyId );
void b2Body_Disable( b2BodyId bodyId );
void b2Body_Enable( b2BodyId bodyId );
void b2Body_SetFixedRotation( b2BodyId bodyId, bool flag );
bool b2Body_IsFixedRotation( b2BodyId bodyId );
void b2Body_SetBullet( b2BodyId bodyId, bool flag );
bool b2Body_IsBullet( b2BodyId bodyId );
void b2Body_EnableHitEvents( b2BodyId bodyId, bool enableHitEvents );
b2AABB b2Body_ComputeAABB( b2BodyId bodyId );

// ### FILTER ###

typedef struct b2Filter
{
    uint32_t categoryBits;
    uint32_t maskBits;
    int32_t groupIndex;
} b2Filter;

b2Filter b2DefaultFilter( void );

// ### SHAPES ###

typedef enum b2ShapeType
{
    b2_circleShape,
    b2_capsuleShape,
    b2_segmentShape,
    b2_polygonShape,
    b2_smoothSegmentShape,
    b2_shapeTypeCount
} b2ShapeType;

typedef struct b2ShapeDef
{
    void* userData;
    float friction;
    float restitution;
    float density;
    b2Filter filter;
    uint32_t customColor;
    bool isSensor;
    bool enableSensorEvents;
    bool enableContactEvents;
    bool enableHitEvents;
    bool enablePreSolveEvents;
    bool forceContactCreation;
    int32_t internalValue;
} b2ShapeDef;

typedef struct b2ShapeId
{
    int32_t index1;
    uint16_t world0;
    uint16_t revision;
} b2ShapeId;

int b2Body_GetShapeCount( b2BodyId bodyId );
int b2Body_GetShapes( b2BodyId bodyId, b2ShapeId* shapeArray, int capacity );

b2ShapeDef b2DefaultShapeDef( void );

void b2DestroyShape( b2ShapeId shapeId );
bool b2Shape_IsValid( b2ShapeId id );
b2ShapeType b2Shape_GetType( b2ShapeId shapeId );
b2BodyId b2Shape_GetBody( b2ShapeId shapeId );
bool b2Shape_IsSensor( b2ShapeId shapeId );
void b2Shape_SetUserData( b2ShapeId shapeId, void* userData );
void* b2Shape_GetUserData( b2ShapeId shapeId );
void b2Shape_SetDensity( b2ShapeId shapeId, float density );
float b2Shape_GetDensity( b2ShapeId shapeId );
void b2Shape_SetFriction( b2ShapeId shapeId, float friction );
float b2Shape_GetFriction( b2ShapeId shapeId );
void b2Shape_SetRestitution( b2ShapeId shapeId, float restitution );
float b2Shape_GetRestitution( b2ShapeId shapeId );
void b2Shape_EnableSensorEvents( b2ShapeId shapeId, bool flag );
bool b2Shape_AreSensorEventsEnabled( b2ShapeId shapeId );
void b2Shape_EnableContactEvents( b2ShapeId shapeId, bool flag );
bool b2Shape_AreContactEventsEnabled( b2ShapeId shapeId );
void b2Shape_EnablePreSolveEvents( b2ShapeId shapeId, bool flag );
bool b2Shape_ArePreSolveEventsEnabled( b2ShapeId shapeId );
void b2Shape_EnableHitEvents( b2ShapeId shapeId, bool flag );
bool b2Shape_AreHitEventsEnabled( b2ShapeId shapeId );
b2AABB b2Shape_GetAABB( b2ShapeId shapeId );
b2Vec2 b2Shape_GetClosestPoint( b2ShapeId shapeId, b2Vec2 target );
b2Filter b2Shape_GetFilter( b2ShapeId shapeId );
void b2Shape_SetFilter( b2ShapeId shapeId, b2Filter filter );

typedef struct b2BodyMoveEvent
{
    b2Transform transform;
    b2BodyId bodyId;
    void* userData;
    bool fellAsleep;
} b2BodyMoveEvent;

typedef struct b2BodyEvents
{
    b2BodyMoveEvent* moveEvents;
    int32_t moveCount;
} b2BodyEvents;

b2BodyEvents b2World_GetBodyEvents( b2WorldId worldId );

typedef struct b2SensorBeginTouchEvent
{
    b2ShapeId sensorShapeId;
    b2ShapeId visitorShapeId;
} b2SensorBeginTouchEvent;

typedef struct b2SensorEndTouchEvent
{
    b2ShapeId sensorShapeId;
    b2ShapeId visitorShapeId;
} b2SensorEndTouchEvent;

typedef struct b2SensorEvents
{
    b2SensorBeginTouchEvent* beginEvents;
    b2SensorEndTouchEvent* endEvents;
    int32_t beginCount;
    int32_t endCount;
} b2SensorEvents;

b2SensorEvents b2World_GetSensorEvents( b2WorldId worldId );

typedef struct b2ContactBeginTouchEvent
{
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
} b2ContactBeginTouchEvent;

typedef struct b2ContactEndTouchEvent
{
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
} b2ContactEndTouchEvent;

typedef struct b2ContactHitEvent
{
    b2ShapeId shapeIdA;
    b2ShapeId shapeIdB;
    b2Vec2 point;
    b2Vec2 normal;
    float approachSpeed;
} b2ContactHitEvent;

typedef struct b2ContactEvents
{
    b2ContactBeginTouchEvent* beginEvents;
    b2ContactEndTouchEvent* endEvents;
    b2ContactHitEvent* hitEvents;
    int32_t beginCount;
    int32_t endCount;
    int32_t hitCount;
} b2ContactEvents;

b2ContactEvents b2World_GetContactEvents( b2WorldId worldId );

// ### CHAINS ###

typedef struct b2ChainDef
{
    void* userData;
    const b2Vec2* points;
    int32_t count;
    float friction;
    float restitution;
    b2Filter filter;
    bool isLoop;
    int32_t internalValue;
} b2ChainDef;

typedef struct b2ChainId
{
    int32_t index1;
    uint16_t world0;
    uint16_t revision;
} b2ChainId;

b2ChainDef b2DefaultChainDef( void );

b2ChainId b2CreateChain( b2BodyId bodyId, const b2ChainDef* def );
void b2DestroyChain( b2ChainId chainId );
void b2Chain_SetFriction( b2ChainId chainId, float friction );
void b2Chain_SetRestitution( b2ChainId chainId, float restitution );
bool b2Chain_IsValid( b2ChainId id );

// ### GEOMETRY ###

typedef struct b2Circle
{
    b2Vec2 center;
    float radius;
} b2Circle;

typedef struct b2Capsule
{
    b2Vec2 center1;
    b2Vec2 center2;
    float radius;
} b2Capsule;

typedef struct b2Polygon
{
    b2Vec2 vertices[8];
    b2Vec2 normals[8];
    b2Vec2 centroid;
    float radius;
    int32_t count;
} b2Polygon;

typedef struct b2Segment
{
    b2Vec2 point1;
    b2Vec2 point2;
} b2Segment;

typedef struct b2SmoothSegment
{
    b2Vec2 ghost1;
    b2Segment segment;
    b2Vec2 ghost2;
    int32_t chainId;
} b2SmoothSegment;

typedef struct b2Hull
{
    b2Vec2 points[8];
    int32_t count;
} b2Hull;

b2Hull b2ComputeHull( const b2Vec2* points, int32_t count );
bool b2ValidateHull( const b2Hull* hull );

b2Polygon b2MakePolygon( const b2Hull* hull, float radius );
b2Polygon b2MakeOffsetPolygon( const b2Hull* hull, float radius, b2Transform transform );
b2Polygon b2MakeSquare( float h );
b2Polygon b2MakeBox( float hx, float hy );
b2Polygon b2MakeRoundedBox( float hx, float hy, float radius );
b2Polygon b2MakeOffsetBox( float hx, float hy, b2Vec2 center, float angle );
b2Polygon b2TransformPolygon( b2Transform transform, const b2Polygon* polygon );

b2ShapeId b2CreateCircleShape( b2BodyId bodyId, const b2ShapeDef* def, const b2Circle* circle );
b2ShapeId b2CreateSegmentShape( b2BodyId bodyId, const b2ShapeDef* def, const b2Segment* segment );
b2ShapeId b2CreateCapsuleShape( b2BodyId bodyId, const b2ShapeDef* def, const b2Capsule* capsule );
b2ShapeId b2CreatePolygonShape( b2BodyId bodyId, const b2ShapeDef* def, const b2Polygon* polygon );
void b2Shape_SetCircle( b2ShapeId shapeId, const b2Circle* circle );
void b2Shape_SetCapsule( b2ShapeId shapeId, const b2Capsule* capsule );
void b2Shape_SetSegment( b2ShapeId shapeId, const b2Segment* segment );
void b2Shape_SetPolygon( b2ShapeId shapeId, const b2Polygon* polygon );
b2Circle b2Shape_GetCircle( b2ShapeId shapeId );
b2Capsule b2Shape_GetCapsule( b2ShapeId shapeId );
b2Segment b2Shape_GetSegment( b2ShapeId shapeId );
b2Polygon b2Shape_GetPolygon( b2ShapeId shapeId );
b2SmoothSegment b2Shape_GetSmoothSegment( b2ShapeId shapeId );

typedef struct b2QueryFilter
{
    uint32_t categoryBits;
    uint32_t maskBits;
} b2QueryFilter;

typedef bool b2OverlapResultFcn( b2ShapeId shapeId, void* context );
void b2World_OverlapAABB( b2WorldId worldId, b2AABB aabb, b2QueryFilter filter, b2OverlapResultFcn* fcn, void* context );
void b2World_OverlapCircle( b2WorldId worldId, const b2Circle* circle, b2Transform transform, b2QueryFilter filter, b2OverlapResultFcn* fcn, void* context );
void b2World_OverlapCapsule( b2WorldId worldId, const b2Capsule* capsule, b2Transform transform, b2QueryFilter filter, b2OverlapResultFcn* fcn, void* context );
void b2World_OverlapPolygon( b2WorldId worldId, const b2Polygon* polygon, b2Transform transform, b2QueryFilter filter, b2OverlapResultFcn* fcn, void* context );

typedef float b2CastResultFcn( b2ShapeId shapeId, b2Vec2 point, b2Vec2 normal, float fraction, void* context );
void b2World_CastRay( b2WorldId worldId, b2Vec2 origin, b2Vec2 translation, b2QueryFilter filter, b2CastResultFcn* fcn, void* context );
void b2World_CastCircle( b2WorldId worldId, const b2Circle* circle, b2Transform originTransform, b2Vec2 translation, b2QueryFilter filter, b2CastResultFcn* fcn, void* context );
void b2World_CastCapsule( b2WorldId worldId, const b2Capsule* capsule, b2Transform originTransform, b2Vec2 translation, b2QueryFilter filter, b2CastResultFcn* fcn, void* context );
void b2World_CastPolygon( b2WorldId worldId, const b2Polygon* polygon, b2Transform originTransform, b2Vec2 translation, b2QueryFilter filter, b2CastResultFcn* fcn, void* context );

typedef struct b2RayResult
{
    b2ShapeId shapeId;
    b2Vec2 point;
    b2Vec2 normal;
    float fraction;
    bool hit;
} b2RayResult;

b2RayResult b2World_CastRayClosest( b2WorldId worldId, b2Vec2 origin, b2Vec2 translation, b2QueryFilter filter );

b2MassData b2ComputeCircleMass( const b2Circle* shape, float density );
b2MassData b2ComputeCapsuleMass( const b2Capsule* shape, float density );
b2MassData b2ComputePolygonMass( const b2Polygon* shape, float density );

b2AABB b2ComputeCircleAABB( const b2Circle* shape, b2Transform transform );
b2AABB b2ComputeCapsuleAABB( const b2Capsule* shape, b2Transform transform );
b2AABB b2ComputePolygonAABB( const b2Polygon* shape, b2Transform transform );
b2AABB b2ComputeSegmentAABB( const b2Segment* shape, b2Transform transform );

bool b2PointInCircle( b2Vec2 point, const b2Circle* shape );
bool b2PointInCapsule( b2Vec2 point, const b2Capsule* shape );
bool b2PointInPolygon( b2Vec2 point, const b2Polygon* shape );

typedef struct b2RayCastInput
{
    b2Vec2 origin;
    b2Vec2 translation;
    float maxFraction;
} b2RayCastInput;

typedef struct b2ShapeCastInput
{
    b2Vec2 points[8];
    int32_t count;
    float radius;
    b2Vec2 translation;
    float maxFraction;
} b2ShapeCastInput;

typedef struct b2CastOutput
{
    b2Vec2 normal;
    b2Vec2 point;
    float fraction;
    int32_t iterations;
    bool hit;
} b2CastOutput;

b2CastOutput b2RayCastCircle( const b2RayCastInput* input, const b2Circle* shape );
b2CastOutput b2RayCastCapsule( const b2RayCastInput* input, const b2Capsule* shape );
b2CastOutput b2RayCastSegment( const b2RayCastInput* input, const b2Segment* shape, bool oneSided );
b2CastOutput b2RayCastPolygon( const b2RayCastInput* input, const b2Polygon* shape );
b2CastOutput b2ShapeCastCircle( const b2ShapeCastInput* input, const b2Circle* shape );
b2CastOutput b2ShapeCastCapsule( const b2ShapeCastInput* input, const b2Capsule* shape );
b2CastOutput b2ShapeCastSegment( const b2ShapeCastInput* input, const b2Segment* shape );
b2CastOutput b2ShapeCastPolygon( const b2ShapeCastInput* input, const b2Polygon* shape );

typedef struct b2ManifoldPoint
{

    b2Vec2 point;
    b2Vec2 anchorA;
    b2Vec2 anchorB;
    float separation;
    float normalImpulse;
    float tangentImpulse;
    float maxNormalImpulse;
    float normalVelocity;
    uint16_t id;
    bool persisted;
} b2ManifoldPoint;

typedef struct b2Manifold
{
    b2ManifoldPoint points[2];
    b2Vec2 normal;
    int32_t pointCount;
} b2Manifold;

b2Manifold b2CollideCircles( const b2Circle* circleA, b2Transform xfA, const b2Circle* circleB, b2Transform xfB );
b2Manifold b2CollideCapsuleAndCircle( const b2Capsule* capsuleA, b2Transform xfA, const b2Circle* circleB, b2Transform xfB );
b2Manifold b2CollideSegmentAndCircle( const b2Segment* segmentA, b2Transform xfA, const b2Circle* circleB, b2Transform xfB );
b2Manifold b2CollidePolygonAndCircle( const b2Polygon* polygonA, b2Transform xfA, const b2Circle* circleB, b2Transform xfB );
b2Manifold b2CollideCapsules( const b2Capsule* capsuleA, b2Transform xfA, const b2Capsule* capsuleB, b2Transform xfB );
b2Manifold b2CollideSegmentAndCapsule( const b2Segment* segmentA, b2Transform xfA, const b2Capsule* capsuleB, b2Transform xfB );
b2Manifold b2CollidePolygonAndCapsule( const b2Polygon* polygonA, b2Transform xfA, const b2Capsule* capsuleB, b2Transform xfB );
b2Manifold b2CollidePolygons( const b2Polygon* polygonA, b2Transform xfA, const b2Polygon* polygonB, b2Transform xfB );
b2Manifold b2CollideSegmentAndPolygon( const b2Segment* segmentA, b2Transform xfA, const b2Polygon* polygonB, b2Transform xfB );

// ### CONTACTS ####

//int b2Body_GetContactCapacity( b2BodyId bodyId );
//int b2Body_GetContactData( b2BodyId bodyId, b2ContactData* contactData, int capacity );

// ### DRAWING ###

typedef enum b2HexColor
{
    b2_colorAliceBlue = 0xf0f8ff,
    b2_colorAntiqueWhite = 0xfaebd7,
    b2_colorAqua = 0x00ffff,
    b2_colorAquamarine = 0x7fffd4,
    b2_colorAzure = 0xf0ffff,
    b2_colorBeige = 0xf5f5dc,
    b2_colorBisque = 0xffe4c4,
    b2_colorBlack = 0x000000,
    b2_colorBlanchedAlmond = 0xffebcd,
    b2_colorBlue = 0x0000ff,
    b2_colorBlueViolet = 0x8a2be2,
    b2_colorBrown = 0xa52a2a,
    b2_colorBurlywood = 0xdeb887,
    b2_colorCadetBlue = 0x5f9ea0,
    b2_colorChartreuse = 0x7fff00,
    b2_colorChocolate = 0xd2691e,
    b2_colorCoral = 0xff7f50,
    b2_colorCornflowerBlue = 0x6495ed,
    b2_colorCornsilk = 0xfff8dc,
    b2_colorCrimson = 0xdc143c,
    b2_colorCyan = 0x00ffff,
    b2_colorDarkBlue = 0x00008b,
    b2_colorDarkCyan = 0x008b8b,
    b2_colorDarkGoldenrod = 0xb8860b,
    b2_colorDarkGray = 0xa9a9a9,
    b2_colorDarkGreen = 0x006400,
    b2_colorDarkKhaki = 0xbdb76b,
    b2_colorDarkMagenta = 0x8b008b,
    b2_colorDarkOliveGreen = 0x556b2f,
    b2_colorDarkOrange = 0xff8c00,
    b2_colorDarkOrchid = 0x9932cc,
    b2_colorDarkRed = 0x8b0000,
    b2_colorDarkSalmon = 0xe9967a,
    b2_colorDarkSeaGreen = 0x8fbc8f,
    b2_colorDarkSlateBlue = 0x483d8b,
    b2_colorDarkSlateGray = 0x2f4f4f,
    b2_colorDarkTurquoise = 0x00ced1,
    b2_colorDarkViolet = 0x9400d3,
    b2_colorDeepPink = 0xff1493,
    b2_colorDeepSkyBlue = 0x00bfff,
    b2_colorDimGray = 0x696969,
    b2_colorDodgerBlue = 0x1e90ff,
    b2_colorFirebrick = 0xb22222,
    b2_colorFloralWhite = 0xfffaf0,
    b2_colorForestGreen = 0x228b22,
    b2_colorFuchsia = 0xff00ff,
    b2_colorGainsboro = 0xdcdcdc,
    b2_colorGhostWhite = 0xf8f8ff,
    b2_colorGold = 0xffd700,
    b2_colorGoldenrod = 0xdaa520,
    b2_colorGray = 0xbebebe,
    b2_colorGray1 = 0x1a1a1a,
    b2_colorGray2 = 0x333333,
    b2_colorGray3 = 0x4d4d4d,
    b2_colorGray4 = 0x666666,
    b2_colorGray5 = 0x7f7f7f,
    b2_colorGray6 = 0x999999,
    b2_colorGray7 = 0xb3b3b3,
    b2_colorGray8 = 0xcccccc,
    b2_colorGray9 = 0xe5e5e5,
    b2_colorGreen = 0x00ff00,
    b2_colorGreenYellow = 0xadff2f,
    b2_colorHoneydew = 0xf0fff0,
    b2_colorHotPink = 0xff69b4,
    b2_colorIndianRed = 0xcd5c5c,
    b2_colorIndigo = 0x4b0082,
    b2_colorIvory = 0xfffff0,
    b2_colorKhaki = 0xf0e68c,
    b2_colorLavender = 0xe6e6fa,
    b2_colorLavenderBlush = 0xfff0f5,
    b2_colorLawnGreen = 0x7cfc00,
    b2_colorLemonChiffon = 0xfffacd,
    b2_colorLightBlue = 0xadd8e6,
    b2_colorLightCoral = 0xf08080,
    b2_colorLightCyan = 0xe0ffff,
    b2_colorLightGoldenrod = 0xeedd82,
    b2_colorLightGoldenrodYellow = 0xfafad2,
    b2_colorLightGray = 0xd3d3d3,
    b2_colorLightGreen = 0x90ee90,
    b2_colorLightPink = 0xffb6c1,
    b2_colorLightSalmon = 0xffa07a,
    b2_colorLightSeaGreen = 0x20b2aa,
    b2_colorLightSkyBlue = 0x87cefa,
    b2_colorLightSlateBlue = 0x8470ff,
    b2_colorLightSlateGray = 0x778899,
    b2_colorLightSteelBlue = 0xb0c4de,
    b2_colorLightYellow = 0xffffe0,
    b2_colorLime = 0x00ff00,
    b2_colorLimeGreen = 0x32cd32,
    b2_colorLinen = 0xfaf0e6,
    b2_colorMagenta = 0xff00ff,
    b2_colorMaroon = 0xb03060,
    b2_colorMediumAquamarine = 0x66cdaa,
    b2_colorMediumBlue = 0x0000cd,
    b2_colorMediumOrchid = 0xba55d3,
    b2_colorMediumPurple = 0x9370db,
    b2_colorMediumSeaGreen = 0x3cb371,
    b2_colorMediumSlateBlue = 0x7b68ee,
    b2_colorMediumSpringGreen = 0x00fa9a,
    b2_colorMediumTurquoise = 0x48d1cc,
    b2_colorMediumVioletRed = 0xc71585,
    b2_colorMidnightBlue = 0x191970,
    b2_colorMintCream = 0xf5fffa,
    b2_colorMistyRose = 0xffe4e1,
    b2_colorMoccasin = 0xffe4b5,
    b2_colorNavajoWhite = 0xffdead,
    b2_colorNavy = 0x000080,
    b2_colorNavyBlue = 0x000080,
    b2_colorOldLace = 0xfdf5e6,
    b2_colorOlive = 0x808000,
    b2_colorOliveDrab = 0x6b8e23,
    b2_colorOrange = 0xffa500,
    b2_colorOrangeRed = 0xff4500,
    b2_colorOrchid = 0xda70d6,
    b2_colorPaleGoldenrod = 0xeee8aa,
    b2_colorPaleGreen = 0x98fb98,
    b2_colorPaleTurquoise = 0xafeeee,
    b2_colorPaleVioletRed = 0xdb7093,
    b2_colorPapayaWhip = 0xffefd5,
    b2_colorPeachPuff = 0xffdab9,
    b2_colorPeru = 0xcd853f,
    b2_colorPink = 0xffc0cb,
    b2_colorPlum = 0xdda0dd,
    b2_colorPowderBlue = 0xb0e0e6,
    b2_colorPurple = 0xa020f0,
    b2_colorRebeccaPurple = 0x663399,
    b2_colorRed = 0xff0000,
    b2_colorRosyBrown = 0xbc8f8f,
    b2_colorRoyalBlue = 0x4169e1,
    b2_colorSaddleBrown = 0x8b4513,
    b2_colorSalmon = 0xfa8072,
    b2_colorSandyBrown = 0xf4a460,
    b2_colorSeaGreen = 0x2e8b57,
    b2_colorSeashell = 0xfff5ee,
    b2_colorSienna = 0xa0522d,
    b2_colorSilver = 0xc0c0c0,
    b2_colorSkyBlue = 0x87ceeb,
    b2_colorSlateBlue = 0x6a5acd,
    b2_colorSlateGray = 0x708090,
    b2_colorSnow = 0xfffafa,
    b2_colorSpringGreen = 0x00ff7f,
    b2_colorSteelBlue = 0x4682b4,
    b2_colorTan = 0xd2b48c,
    b2_colorTeal = 0x008080,
    b2_colorThistle = 0xd8bfd8,
    b2_colorTomato = 0xff6347,
    b2_colorTurquoise = 0x40e0d0,
    b2_colorViolet = 0xee82ee,
    b2_colorVioletRed = 0xd02090,
    b2_colorWheat = 0xf5deb3,
    b2_colorWhite = 0xffffff,
    b2_colorWhiteSmoke = 0xf5f5f5,
    b2_colorYellow = 0xffff00,
    b2_colorYellowGreen = 0x9acd32,
    b2_colorBox2DRed = 0xdc3132,
    b2_colorBox2DBlue = 0x30aebf,
    b2_colorBox2DGreen = 0x8cc924,
    b2_colorBox2DYellow = 0xffee8c
} b2HexColor;

typedef struct b2DebugDraw
{
    void ( *DrawPolygon )( const b2Vec2* vertices, int vertexCount, b2HexColor color, void* context );
    void ( *DrawSolidPolygon )( b2Transform transform, const b2Vec2* vertices, int vertexCount, float radius, b2HexColor color,void* context );
    void ( *DrawCircle )( b2Vec2 center, float radius, b2HexColor color, void* context );
    void ( *DrawSolidCircle )( b2Transform transform, float radius, b2HexColor color, void* context );
    void ( *DrawCapsule )( b2Vec2 p1, b2Vec2 p2, float radius, b2HexColor color, void* context );
    void ( *DrawSolidCapsule )( b2Vec2 p1, b2Vec2 p2, float radius, b2HexColor color, void* context );
    void ( *DrawSegment )( b2Vec2 p1, b2Vec2 p2, b2HexColor color, void* context );
    void ( *DrawTransform )( b2Transform transform, void* context );
    void ( *DrawPoint )( b2Vec2 p, float size, b2HexColor color, void* context );
    void ( *DrawString )( b2Vec2 p, const char* s, void* context );

    b2AABB drawingBounds;
    bool useDrawingBounds;
    bool drawShapes;
    bool drawJoints;
    bool drawJointExtras;
    bool drawAABBs;
    bool drawMass;
    bool drawContacts;
    bool drawGraphColors;
    bool drawContactNormals;
    bool drawContactImpulses;
    bool drawFrictionImpulses;
    void* context;
} b2DebugDraw;

typedef struct SubStruct {} SubStruct;

typedef struct Struct
{
    void (*fn_pointer_sub_ptr)(SubStruct* x);
    void (*fn_pointer_sub_value)(SubStruct x);
} Struct;

void b2World_Draw( b2WorldId worldId, b2DebugDraw* draw );
