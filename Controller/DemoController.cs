using System;
using UnityEngine;
using System.Collections;

[RequireComponent(typeof(CharacterController))]
public class DemoController : MonoBehaviour
{
    //FIELDS
    //--- References ---
    private Animator _myAnimator;
    private CharacterController _characterController;
    //--- Parameters ---
    private float _coverRadius = 0.75f;
    private float _coverOffset = 0.1f;
    [SerializeField]
    private LayerMask _coverLayerMask = new LayerMask();
    private RaycastHit _hitInfo; //Member because of exceeding cover
    private bool _inCover = false;
    private float _coverDirection = 0.0f;

    private Vector3 _previousPosition = Vector3.zero;

    //METHODS
    // Use this for initialization
    void Start ()
	{
        //Get references
        _myAnimator = this.GetComponent<Animator>();
        _characterController = this.GetComponent<CharacterController>();
	}
	
	// Update is called once per frame
	void Update ()
    {
        Debug.DrawLine(_characterController.transform.position + Vector3.up, _characterController.transform.position + new Vector3(_coverRadius,1,0));
        Debug.DrawLine(_characterController.transform.position + Vector3.up, _characterController.transform.position + new Vector3(-_coverRadius, 1, 0));
        Debug.DrawLine(_characterController.transform.position + Vector3.up, _characterController.transform.position + new Vector3(0, 1, _coverRadius));
        Debug.DrawLine(_characterController.transform.position + Vector3.up, _characterController.transform.position + new Vector3(0, 1, -_coverRadius));

        //OVERALL VARIABLES - INPUT
        //Check for Movement + Orientation (Left, Right, Up, Down locked to movement ifo camera, Diagonal allowed)
        Vector2 input = new Vector2(Input.GetAxis("Horizontal"), Input.GetAxis("Vertical"));
        //Walk
        float speed = Convert.ToInt32(Math.Abs(input.x) > float.Epsilon || Math.Abs(input.y) > float.Epsilon);
        speed = Mathf.Clamp(Mathf.Abs(input.x) + Mathf.Abs(input.y), 0, 1);

        //COVER
        if (Input.GetKey(KeyCode.Space))
	    {
	        //SphereOverlap to receive all collider!
	        Collider[] colliders = Physics.OverlapSphere(_characterController.transform.position,
	            _coverRadius, _coverLayerMask);

	        //Find closest and move towards that position + check normal for orientation
	        Vector3 currentPosition = _characterController.transform.position;
	        Collider closestCollider = null;
	        foreach (Collider c in colliders)
	        {
	            if (closestCollider == null)
	                closestCollider = c;

	            //Distance calculation
	            float distanceClosest = Vector3.Distance(currentPosition, closestCollider.transform.position);
	            float distanceC = Vector3.Distance(currentPosition, c.transform.position);
	            if (distanceC < distanceClosest)
	                closestCollider = c;
	        }

	        //Debug Lines
	        foreach (Collider c in colliders)
	        {
	            Debug.DrawLine(currentPosition + Vector3.up, c.transform.position + Vector3.up, Color.green);
	        }

	        //If we found one
	        if (closestCollider != null)
	        {
	            //Make one of 4 straight directions based on direction vector
	            Vector3 direction = (closestCollider.transform.position - currentPosition).normalized;
	            direction.x = Mathf.Round(direction.x);
	            direction.y = 0;
	            direction.z = Mathf.Round(direction.z);

	            //Debug Lines
	            Debug.DrawLine(_characterController.transform.position + Vector3.up,
	                closestCollider.transform.position + Vector3.up, Color.red);
	            Debug.DrawLine(_characterController.transform.position + Vector3.up,
	                _characterController.transform.position + Vector3.up + direction, Color.blue);

                //MOVEMENT IN COVER
                //Allow movement if input is perpendicular to surface (dot product)
                Vector3 v1 = new Vector3(_hitInfo.normal.x, 0, _hitInfo.normal.z);
                Vector3 v2 = new Vector3(input.x, 0, input.y);
                float angle = AngleSigned(v1, v2, Vector3.up);

                if (Math.Abs(angle - (-90)) < float.Epsilon) //-90
                    _coverDirection = -1.0f;
                else if (Math.Abs(angle - 90) < float.Epsilon) //90
                    _coverDirection = 1.0f;
                //CoverDirection based on Input
                _coverDirection *= speed;

                //The position NEXT FRAME!
	            Vector3 targetDirection = transform.forward*_coverDirection;
                Vector3 targetPosition = _characterController.transform.position + targetDirection
                    * speed * Time.deltaTime;

                //Raycast using the direction
                Debug.DrawRay(currentPosition + _characterController.center, direction, Color.magenta);
	            if (Physics.Raycast(targetPosition + _characterController.center, direction, out _hitInfo, _coverRadius,
	                _coverLayerMask))
	            {
                    //Store position of current frame
                    _previousPosition = _characterController.transform.position;
                    //Move player to surface (take into account the width of the charactercontroller
                    Vector3 diff = new Vector3(_hitInfo.normal.x*(_characterController.bounds.size/2).x,
	                    0, _hitInfo.normal.z*(_characterController.bounds.size/2).z);
	                Vector3 offset = _hitInfo.normal*_coverOffset;
	                Vector3 newPosition = _hitInfo.point + diff + offset; //World pos point + difference because of size CC
	                newPosition.y = currentPosition.y; //Remember we moved it to center to make sure we can cast
	                _characterController.transform.position = newPosition;
                    //Play audio
	                if (_inCover == false)
	                {
	                    AudioManager.Instance.PlayAgainstWallSound();
	                }
	                //Flags
	                _inCover = true;
	            }
	            else if (_inCover) //Next frame we did not hit a collider BUT we were in cover (==exceeding corner)
	            {
	                Debug.Log("Exceeding corner!!");
                    _characterController.transform.position = _previousPosition; //To avoid lock 
	            }

                //Orientation determination
                Quaternion targetRotation = _characterController.transform.rotation;
                if (_hitInfo.normal.Equals(Vector3.left))
                    targetRotation = Quaternion.Euler(0, -90, 0);
                else if (_hitInfo.normal.Equals(Vector3.forward))
                    targetRotation = Quaternion.identity;
                else if (_hitInfo.normal.Equals(Vector3.right))
                    targetRotation = Quaternion.Euler(0, 90, 0);
                else if (_hitInfo.normal.Equals(Vector3.back))
                    targetRotation = Quaternion.Euler(0, 180, 0);
                //Rotating CharacterController Instant
	            _characterController.transform.rotation = targetRotation;
	        }
	    }
        //NOT COVER
        else
        {
            //In Cover variables reset
            _inCover = false;
            _coverDirection = 0.0f;

            //MOVEMENT NOT IN COVER
            //Orientation determination
            Quaternion targetRotation = _characterController.transform.rotation;
	        if (input.x < 0 && Math.Abs(input.y) < float.Epsilon) //Left: x -1, y 0
	            targetRotation = Quaternion.Euler(0, -90, 0);
	        else if (Math.Abs(input.x) < float.Epsilon && input.y > 0) //Forward: x 0, y 1
	            targetRotation = Quaternion.Euler(0, 0, 0);
	        else if (input.x > 0 && Math.Abs(input.y) < float.Epsilon) //Right: x 1, y 0
	            targetRotation = Quaternion.Euler(0, 90, 0);
	        else if (Math.Abs(input.x) < float.Epsilon && input.y < 0) //Backwards: x 0, y -1
	            targetRotation = Quaternion.Euler(0, 180, 0);
	        else if (input.x < 0 && input.y > 0) //Diagonal LF: x -1, y 1
	            targetRotation = Quaternion.Euler(0, -45, 0);
	        else if (input.x > 0 && input.y > 0) //Diagonal RF: x 1, y 1
	            targetRotation = Quaternion.Euler(0, 45, 0);
	        else if (input.x < 0 && input.y < 0) //Diagonal LB: x -1, y -1
	            targetRotation = Quaternion.Euler(0, -135, 0);
	        else if (input.x > 0 && input.y < 0) //Diagonal RB: x 1, y -1
	            targetRotation = Quaternion.Euler(0, 135, 0);
	        //Rotating CharacterController
	        float rotationSpeed = 0.25f;
	        _characterController.transform.rotation = Quaternion.Slerp(
	            _characterController.transform.rotation, targetRotation, rotationSpeed);
	    }

        //ANIMATION VARIABLES
        _myAnimator.SetFloat("Speed", speed);
        _myAnimator.SetBool("InCover", _inCover);
        _myAnimator.SetFloat("CoverDirection", _coverDirection); 
    }


    private float AngleSigned(Vector3 v1, Vector3 v2, Vector3 n)
    {
        return Mathf.Atan2( Vector3.Dot(n, Vector3.Cross(v1, v2)),Vector3.Dot(v1, v2)) * Mathf.Rad2Deg;
    }
}
