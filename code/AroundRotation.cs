using Sandbox;

public sealed class AroundRotation : Component
{
	
	[Property]public float speed = 2f; // 移动速度
	[Property]public float distance = 5f; // 移动距离
	[Property]private Vector3 direction = Vector3.Right; // 移动方向（初始向右）
	
	private Vector3 tagetpos;
	[Property]public float lerp = 1f; // lerp值
	
	private Vector3 startPos ; // 初始位置
	private Vector3 LeftPos ; // 初始位置
	private Vector3 RightPos ; // 初始位置

	protected override void OnStart()
	{

		startPos = Transform.Position;
		LeftPos = startPos + direction * distance;
		RightPos = startPos - direction * distance;
	}

	protected override void OnUpdate()
	{
		
		if ( Transform.Position ==LeftPos)
		{
			direction = -direction;
		}
		if ( Transform.Position ==RightPos)
		{
			direction = -direction;
		}
		tagetpos = Transform.Position + direction;
		Transform.Position = Vector3.Lerp(Transform.Position, tagetpos , lerp);
		Draw();
		
	}
	void Draw()
	{
		LeftPos = startPos + direction * distance;
		RightPos = startPos - direction * distance;
	
		Gizmo.Draw.Color = Color.Orange;
		Gizmo.Draw.LineThickness = 1f;
		Gizmo.Draw.LineSphere(LeftPos,4 );
		Gizmo.Draw.LineSphere(RightPos,4 );
		Gizmo.Draw.Color = Color.Green;
		Gizmo.Draw.LineThickness = 5f;
		Gizmo.Draw.Arrow( startPos,Transform.Position );
		
	}

}
