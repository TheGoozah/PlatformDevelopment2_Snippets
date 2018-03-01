using UnityEngine;

//T needs to be a monobehaviour becase we need Coroutines
public class Singleton<T> : MonoBehaviour where T : MonoBehaviour
{
    //FIELDS
    private static T _instance = null;
    private static object _lock = new object();
    private static bool _applicationIsQuitting = false;

    //METHODS
    public static T Instance
    {
        get
        {
            //If application is Quitting we don't want to create one again.
            //This is necessary because we have no control over order of execution
            if (_applicationIsQuitting)
            {
                Debug.LogWarning("Singleton Instance of " + typeof(T) + " is already destroyed by the application");
                return null;
            }

            //Lock when we ask for the instance
            lock (_lock)
            {
                //If there is no instance yet
                if (_instance == null)
                {
                    //Check in scene if there is an object of the same name with the component
                    _instance = FindObjectOfType(typeof (T)) as T;

                    //If there are more... something is wrong!
                    if (FindObjectsOfType(typeof (T)).Length > 1)
                    {
                        Debug.LogError("More than one instance of singleton " + typeof(T));
                        return _instance; //Return first instance though
                    }

                    //If none in scene, create it ourselves
                    if (_instance == null)
                    {
                        GameObject singleton = new GameObject(typeof(T).ToString());
                        _instance = singleton.AddComponent<T>();

                        //Flag to not be destroyed on load -- level switching for example
                        DontDestroyOnLoad(singleton);

                        Debug.Log("Create instance of singleton " + typeof(T));
                    }
                }

                //Else return instance
                return _instance;
            }
        }
    }

    protected Singleton()
    {} 

    //When object is being destroyed, flag the bool ourselves
    public void OnDestroy()
    {
        _applicationIsQuitting = true;
    }
}
