using System.Linq;
using Sandbox;
using Sandbox.Citizen;

public sealed class NavMesh : Component
{
	private NavMeshAgent _navMeshAgent => Components.Get<NavMeshAgent>();
	private CitizenAnimationHelper _citizenAnimationHelper => Components.Get<CitizenAnimationHelper>();
	[Property] public GameObject target;
	[Property] public float Attackdistance = 100f;

	
	protected override void OnStart()
	{
		var gameObjects = Scene.GetAllObjects( true ).Where( obj => obj.Tags.Has( "player" ) );
		if ( !gameObjects.Any() ) return;
		var objects = gameObjects.ToList();
		foreach ( var o in objects )
		{
			target = o;
		}
	}

	protected override void OnUpdate()
	{
		if(target is null) return;
		
		_citizenAnimationHelper.WithVelocity( _navMeshAgent.Velocity );
		_citizenAnimationHelper.WithWishVelocity( _navMeshAgent.WishVelocity );
		Draw();
		float distance = Vector3.DistanceBetween( Transform.Position, target.Transform.Position );
		if ( distance < Attackdistance )
		{
			_navMeshAgent.MoveTo( target.Transform.Position );
		}
		else
		{
			_navMeshAgent.Stop();
		}
	}

	void Draw()
	{
		Gizmo.Draw.Color = Color.Cyan;
		Gizmo.Draw.LineThickness = 1f;
		Gizmo.Draw.Arrow( Transform.Position,target.Transform.Position );
		Gizmo.Draw.LineSphere( Transform.Position,Attackdistance,64 );
	}
}
