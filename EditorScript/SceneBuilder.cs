using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

//Add Editor
using UnityEditor;

public class SceneBuilder : EditorWindow
{
    //FIELDS
    //------ GRID ------
    private static int _gridWidth = 10;
    private static int _gridDepth = 10;
    private static Vector3 _tileScale = Vector3.one;
    private static GameObject _tilePrefab = null;

    private GUIStyle _tilePrefabPreviewStyle;
    private static GameObject _parentGridObject;

    //------- PLACEMENT --------
    private bool _inBuildMode = false;
    private static List<GameObject> _placementPrefabs = new List<GameObject>();
    private static int _currentPlacementPrefabIndex = 0;
    private static GameObject _parentObjectsInSceneObject = null;

    //METHODS
    //Add this editor to the Menu
    [MenuItem("DAE/SceneBuilder")]
    //The default behavior in Unity is to recycle windows, this can be done with GetWindow
    public static void ShowWindow()
    {
        var window = EditorWindow.GetWindow(typeof(SceneBuilder));
        window.maxSize = new Vector2(250.0f, 600.0f);
        window.minSize = window.maxSize;
    }

    void Awake()
    {
        //Tile Prefab Style
        _tilePrefabPreviewStyle = new GUIStyle();
        _tilePrefabPreviewStyle.fixedHeight = 100;
        _tilePrefabPreviewStyle.alignment = TextAnchor.MiddleLeft;
    }

    //GUI
    void OnGUI()
    {
        //GRID SIZE
        GUILayout.Label("Grid Settings", EditorStyles.boldLabel);
        EditorGUILayout.BeginHorizontal();
        {
            EditorGUILayout.BeginVertical();
            {
                //Size of Grid + Scale
                EditorGUIUtility.labelWidth = 80;
                _gridWidth = EditorGUILayout.IntField("Grid Width: ", _gridWidth);
                _gridDepth = EditorGUILayout.IntField("Grid Depth: ", _gridDepth);
                _tileScale = EditorGUILayout.Vector3Field("Tile Scale: ", _tileScale);
                //Prefab
                _tilePrefab = EditorGUILayout.ObjectField("Tile Prefab: ", _tilePrefab, typeof(GameObject), false) as GameObject;
                //Button
                if (GUILayout.Button("Apply"))
                {
                    BuildGrid();
                }
            }
            EditorGUILayout.EndVertical();

            GUILayout.FlexibleSpace();
            EditorGUILayout.BeginVertical();
            {
                //Image prefab
                if (_tilePrefab)
                {
                    //GUILayoutOption[] options = new GUILayoutOption[] { GUILayout.Height(100.0f) };
                    Texture2D myTexture = AssetPreview.GetAssetPreview(_tilePrefab);
                    GUILayout.Label(myTexture, _tilePrefabPreviewStyle);
                }
            }
            EditorGUILayout.EndVertical();
        }
        EditorGUILayout.EndHorizontal();
        
        //PLACEMENT
        EditorGUILayout.Space();
        GUILayout.Label("Placement", EditorStyles.boldLabel);
        EditorGUILayout.BeginHorizontal();
        {
            EditorGUILayout.BeginVertical();
            {
                //Button
                EditorGUILayout.BeginHorizontal();
                {
                    //Adjust list (Add/Remove)
                    if (GUILayout.Button("+"))
                    {
                        _placementPrefabs.Add(null);
                    }
                    if (GUILayout.Button("-") && _placementPrefabs.Count != 0)
                    {
                        _placementPrefabs.Remove(_placementPrefabs[_placementPrefabs.Count - 1]);
                    }
                }
                EditorGUILayout.EndHorizontal();
                //Prefabs
                for (int i = 0; i < _placementPrefabs.Count; i++)
                {
                    _placementPrefabs[i] =
                        EditorGUILayout.ObjectField("Prefab " + i + ": ", _placementPrefabs[i], typeof (GameObject),
                            false) as GameObject;
                }
                //Information
                _currentPlacementPrefabIndex = EditorGUILayout.IntField("Current: ", _currentPlacementPrefabIndex);
                if (_currentPlacementPrefabIndex < 0)
                    _currentPlacementPrefabIndex = 0;

                //Button
                _inBuildMode = GUILayout.Toggle(_inBuildMode, "Place Objects", "Button");
            }
            EditorGUILayout.EndVertical();
        }
        EditorGUILayout.EndHorizontal();
    }

    //Link to receive events of scene
    void OnEnable()
    {
        SceneView.onSceneGUIDelegate += OnSceneGUI;
    }
    void OnDisable()
    {
        SceneView.onSceneGUIDelegate -= OnSceneGUI;
    }

    //Process Scene events
    public void OnSceneGUI(SceneView sceneView)
    {
        if (_inBuildMode && _placementPrefabs.Count > 0)
        {
            //Get current event and ID
            Event e = Event.current;
            //int controlID = GUIUtility.GetControlID(FocusType.Passive);

            //If left mouse button spawn object at hit point
            if (e.type == EventType.mouseDown && e.button == 0 && !e.control && !e.alt)
            {
                Ray ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
                RaycastHit hit;
                if (Physics.Raycast(ray, out hit, 1000))
                {
                    //Create parent if none existing
                    if(!_parentObjectsInSceneObject)
                        _parentObjectsInSceneObject = new GameObject("PlacedObjects");

                    //Create GO
                    var prefab = _placementPrefabs[_currentPlacementPrefabIndex];
                    GameObject obj = Instantiate(prefab, Vector3.zero, prefab.transform.rotation) as GameObject;

                    //Position correctly
                    Vector3 bounds = Vector3.zero;
                    Renderer ren = obj.GetComponent<Renderer>();
                    if (ren)
                        bounds = ren.bounds.size;
                    Vector3 position = hit.point + new Vector3(
                        hit.normal.x * (bounds.x / 2), 
                        hit.normal.y * (bounds.y / 2), 
                        hit.normal.z * (bounds.z / 2));
                    obj.transform.position = position;
                    //Parent
                    obj.transform.parent = _parentObjectsInSceneObject.transform;
                }
            }
            else if (e.type == EventType.KeyDown)
            {
                //Increment index
                if (e.keyCode == KeyCode.LeftControl)
                {
                    ++_currentPlacementPrefabIndex;
                    if (_currentPlacementPrefabIndex > _placementPrefabs.Count - 1)
                        _currentPlacementPrefabIndex = 0;

                    //Repaint to show our value has changed in code
                    Repaint();
                }
            }
        }
    }

    private void BuildGrid()
    {
        if (!_tilePrefab)
            return;

        if (!_parentGridObject)
            _parentGridObject = new GameObject("Grid");
        else
        {
            //Destroy all children, get temp list to be able to work with DestroyImmediate
            var tempList = _parentGridObject.GetComponentsInChildren<Transform>().Where
                (x => x.gameObject.transform.parent != null).ToList();
            foreach (var child in tempList)
            {
                DestroyImmediate(child.gameObject);
            }
        }

        //Start Location + scale
        Vector3 location = Vector3.zero;
        Vector3 scale = new Vector3(
            _tilePrefab.transform.localScale.x * _tileScale.x,
            _tilePrefab.transform.localScale.y * _tileScale.y,
            _tilePrefab.transform.localScale.z * _tileScale.z);
        //Create grid
        for (int x = 0; x < _gridWidth; ++x)
        {
            location.x = scale.x * x;
            for (int d = 0; d < _gridDepth; ++d)
            {
                //Get scale
                location.z = scale.z * d;
                GameObject go = Instantiate(_tilePrefab, location, _tilePrefab.transform.rotation, _parentGridObject.transform) as GameObject;
                go.transform.localScale = scale;
            }
        }
    }
}
