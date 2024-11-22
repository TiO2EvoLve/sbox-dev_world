using Sandbox;

public sealed class CollisionTest : Component,Component.ICollisionListener
{
	private Rigidbody Rigidbody;
	[Property]public int power { get; set; }
	private TimeSince TimeSince;
	
	
	protected override void OnStart()
	{
		Rigidbody = Components.Get<Rigidbody>();
	}
	
	protected override void OnUpdate()
	{
		
	}

	public void OnCollisionStart( Collision other )
	{
		if ( TimeSince >= 0.2)
		{
			Rigidbody.ApplyForce( Vector3.Up * power);
			TimeSince = 0;
		}
	}

	public void OnCollisionUpdate( Collision other )
	{
	}

	public void OnCollisionStop( CollisionStop other )
	{
	}
}
