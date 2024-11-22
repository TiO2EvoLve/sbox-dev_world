using System.Linq;
using Sandbox;
using Sandbox.Citizen;

public sealed class NavTest : Component
{

	private GameObject Player { get; set; }
	[Property]
	private float HatredDistance { get; set; } = 500f;
	[Property]
	private float StopDistance { get; set; } = 30f;
	private NavMeshAgent Agent =>Components.Get<NavMeshAgent>();
	private SkinnedModelRenderer Target =>Components.Get<SkinnedModelRenderer>();
	private CitizenAnimationHelper Anim =>Components.Get<CitizenAnimationHelper>();
	private float distance;
	private TimeSince _timeSince;
	[Property] public float SearchTime = 2f;
	
	protected override void OnUpdate()
	{
		DrawHatredDistance();
		Anim.WithVelocity(Agent.Velocity);
		Anim.WithWishVelocity(Agent.WishVelocity);
		
		if ( Player is not null )
		{
			distance = Vector3.DistanceBetween(Transform.Position, Player.Transform.Position);
			if( _timeSince > SearchTime && distance < HatredDistance)
			{
				SearchPlayer();
				_timeSince = 0;
			}
		}else
		{
			SearchPlayer();
		} 
		if ( distance > HatredDistance )
		{
			Agent.Stop();
			return;
		}
		
		Draw();
		
		Anim.HoldType = CitizenAnimationHelper.HoldTypes.None;
		if (distance > StopDistance)
		{
			Agent.MoveTo(Player.Transform.Position);
		}
		else
		{
			Agent.Stop();
			Anim.HoldType = CitizenAnimationHelper.HoldTypes.Punch;
		}
	}
	void Draw()
	{
		if ( Player is not null )
		{
			Gizmo.Draw.Color = Color.Green;
			Gizmo.Draw.LineThickness = 5;
			Gizmo.Draw.Arrow( Transform.Position, Player.Transform.Position );

			Gizmo.Draw.Color = Color.Red;
			Gizmo.Draw.LineThickness = 1;
			var triangles = Scene.NavMesh.GetSimplePath( Transform.Position, Player.Transform.Position );

			var up = Vector3.Up * 32.0f;

			for ( int i = 1; i < triangles.Count; i++ )
			{
				Gizmo.Draw.Arrow( up + triangles[i - 1], up + triangles[i] );
			}
		}
	}
	
	void DrawHatredDistance()
	{
			Gizmo.Draw.Color = Color.Green;
			Gizmo.Draw.LineThickness = 1;
			if ( distance < HatredDistance ) Gizmo.Draw.Color = Color.Red;
			Gizmo.Draw.LineSphere( Transform.Position,HatredDistance,32 );
	}

	void SearchPlayer()
	{
		var gameObjects = Scene.GetAllObjects( true ).Where( obj => obj.Tags.Has( "body" ) );
		if ( !gameObjects.Any() ) return;
		var objects = gameObjects.ToList();
		foreach ( var o in objects )
		{
			Player = o;
		}
	}
}
