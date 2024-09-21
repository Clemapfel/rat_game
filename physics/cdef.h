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

void b2SetLengthUnitsPerMeter 	( 	float 	lengthUnits	);

float b2Atan2( float y, float x );
float b2MinFloat( float a, float b );
float b2MaxFloat( float a, float b );
float b2AbsFloat( float a );
float b2ClampFloat( float a, float lower, float upper );
int b2MinInt( int a, int b );
int b2MaxInt( int a, int b );
int b2AbsInt( int a );
int b2ClampInt( int a, int lower, int upper );
float b2Dot( b2Vec2 a, b2Vec2 b );
float b2Cross( b2Vec2 a, b2Vec2 b );
b2Vec2 b2CrossVS( b2Vec2 v, float s );
b2Vec2 b2CrossSV( float s, b2Vec2 v );
b2Vec2 b2LeftPerp( b2Vec2 v );
b2Vec2 b2RightPerp( b2Vec2 v );
b2Vec2 b2Add( b2Vec2 a, b2Vec2 b );
b2Vec2 b2Sub( b2Vec2 a, b2Vec2 b );
b2Vec2 b2Neg( b2Vec2 a );
b2Vec2 b2Lerp( b2Vec2 a, b2Vec2 b, float t );
b2Vec2 b2Mul( b2Vec2 a, b2Vec2 b );
b2Vec2 b2MulSV( float s, b2Vec2 v );
b2Vec2 b2MulAdd( b2Vec2 a, float s, b2Vec2 b );
b2Vec2 b2MulSub( b2Vec2 a, float s, b2Vec2 b );
b2Vec2 b2Abs( b2Vec2 a );
b2Vec2 b2Min( b2Vec2 a, b2Vec2 b );
b2Vec2 b2Max( b2Vec2 a, b2Vec2 b );
b2Vec2 b2Clamp( b2Vec2 v, b2Vec2 a, b2Vec2 b );
float b2Length( b2Vec2 v );
float b2Distance( b2Vec2 a, b2Vec2 b );
b2Vec2 b2Normalize( b2Vec2 v );
b2Vec2 b2GetLengthAndNormalize( float* length, b2Vec2 v );
b2Rot b2NormalizeRot( b2Rot q );
b2Rot b2IntegrateRotation( b2Rot q1, float deltaAngle );
float b2LengthSquared( b2Vec2 v );
float b2DistanceSquared( b2Vec2 a, b2Vec2 b );
b2Rot b2MakeRot( float angle );
bool b2IsNormalized( b2Rot q );
b2Rot b2NLerp( b2Rot q1, b2Rot q2, float t );
float b2ComputeAngularVelocity( b2Rot q1, b2Rot q2, float inv_h );
float b2Rot_GetAngle( b2Rot q );
b2Vec2 b2Rot_GetXAxis( b2Rot q );
b2Vec2 b2Rot_GetYAxis( b2Rot q );
b2Rot b2MulRot( b2Rot q, b2Rot r );
b2Rot b2InvMulRot( b2Rot q, b2Rot r );
float b2RelativeAngle( b2Rot b, b2Rot a );
float b2UnwindAngle( float angle );
float b2UnwindLargeAngle( float angle );
b2Vec2 b2RotateVector( b2Rot q, b2Vec2 v );
b2Vec2 b2InvRotateVector( b2Rot q, b2Vec2 v );
b2Vec2 b2TransformPoint( b2Transform t, const b2Vec2 p );
b2Vec2 b2InvTransformPoint( b2Transform t, const b2Vec2 p );
b2Transform b2MulTransforms( b2Transform A, b2Transform B );
b2Transform b2InvMulTransforms( b2Transform A, b2Transform B );
b2Vec2 b2MulMV( b2Mat22 A, b2Vec2 v );
b2Mat22 b2GetInverse22( b2Mat22 A );
b2Vec2 b2Solve22( b2Mat22 A, b2Vec2 b );
bool b2AABB_Contains( b2AABB a, b2AABB b );
b2Vec2 b2AABB_Center( b2AABB a );
b2Vec2 b2AABB_Extents( b2AABB a );
b2AABB b2AABB_Union( b2AABB a, b2AABB b );
bool b2IsValid( float a );
bool b2Vec2_IsValid( b2Vec2 v );
bool b2Rot_IsValid( b2Rot q );
bool b2AABB_IsValid( b2AABB aabb );
void b2SetLengthUnitsPerMeter( float lengthUnits );
float b2GetLengthUnitsPerMeter( void );

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
b2QueryFilter b2DefaultQueryFilter( void );

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

// ### JOINTS ###

typedef struct b2JointId
{
    int32_t index1;
    uint16_t world0;
    uint16_t revision;
} b2JointId;

int b2Body_GetJointCount( b2BodyId bodyId );
int b2Body_GetJoints( b2BodyId bodyId, b2JointId* jointArray, int capacity );

typedef enum b2JointType
{
    b2_distanceJoint,
    b2_motorJoint,
    b2_mouseJoint,
    b2_prismaticJoint,
    b2_revoluteJoint,
    b2_weldJoint,
    b2_wheelJoint,
} b2JointType;

void b2DestroyJoint( b2JointId jointId );
bool b2Joint_IsValid( b2JointId id );
b2JointType b2Joint_GetType( b2JointId jointId );
b2BodyId b2Joint_GetBodyA( b2JointId jointId );
b2BodyId b2Joint_GetBodyB( b2JointId jointId );
b2Vec2 b2Joint_GetLocalAnchorA( b2JointId jointId );
b2Vec2 b2Joint_GetLocalAnchorB( b2JointId jointId );
void b2Joint_SetCollideConnected( b2JointId jointId, bool shouldCollide );
bool b2Joint_GetCollideConnected( b2JointId jointId );
void b2Joint_SetUserData( b2JointId jointId, void* userData );
void* b2Joint_GetUserData( b2JointId jointId );
void b2Joint_WakeBodies( b2JointId jointId );
b2Vec2 b2Joint_GetConstraintForce( b2JointId jointId );
float b2Joint_GetConstraintTorque( b2JointId jointId );

typedef struct b2DistanceJointDef
{
    b2BodyId bodyIdA;
    b2BodyId bodyIdB;
    b2Vec2 localAnchorA;
    b2Vec2 localAnchorB;

    float length;
    bool enableSpring;
    float hertz;
    float dampingRatio;
    bool enableLimit;
    float minLength;
    float maxLength;
    bool enableMotor;
    float maxMotorForce;
    float motorSpeed;
    bool collideConnected;
    void* userData;
    int32_t internalValue;
} b2DistanceJointDef;

b2DistanceJointDef b2DefaultDistanceJointDef( void );
b2JointId b2CreateDistanceJoint( b2WorldId worldId, const b2DistanceJointDef* def );

typedef struct b2MouseJointDef
{
    b2BodyId bodyIdA;
    b2BodyId bodyIdB;
    b2Vec2 target;

    float hertz;
    float dampingRatio;
    float maxForce;
    bool collideConnected;
    void* userData;
    int32_t internalValue;
} b2MouseJointDef;

b2MouseJointDef b2DefaultMouseJointDef( void );
b2JointId b2CreateMouseJoint( b2WorldId worldId, const b2MouseJointDef* def );

typedef struct b2WeldJointDef
{
    b2BodyId bodyIdA;
    b2BodyId bodyIdB;
    b2Vec2 localAnchorA;
    b2Vec2 localAnchorB;
    float referenceAngle;
    float linearHertz;
    float angularHertz;
    float linearDampingRatio;
    float angularDampingRatio;
    bool collideConnected;
    void* userData;
    int32_t internalValue;
} b2WeldJointDef;

b2WeldJointDef b2DefaultWeldJointDef( void );
b2JointId b2CreateWeldJoint( b2WorldId worldId, const b2WeldJointDef* def );

// ### CONTACTS ####

//int b2Body_GetContactCapacity( b2BodyId bodyId );
//int b2Body_GetContactData( b2BodyId bodyId, b2ContactData* contactData, int capacity );

// ### THREADS ###
