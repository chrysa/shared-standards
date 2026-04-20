# game-dev-CLAUDE.md

## Game Development AI Assistant Configuration

This file configures Claude AI for game development tasks using Blender and Unity.

---

## 1. BLENDER PYTHON GENERATION

### Guidelines

- **Language**: Python (Blender 3.x+ API)
- **Module**: `bpy` (Blender Python)
- **Style**: DRY, modular, reusable scripts

### Core Patterns

```python
# Pattern 1: Scene Setup
import bpy

def create_scene():
    scene = bpy.data.scenes.new("GameScene")
    scene.render.engine = 'CYCLES'  # or EEVEE
    return scene

# Pattern 2: Mesh Generation
def create_mesh(name, vertices, faces):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj

# Pattern 3: Material Creation
def create_material(name, color, roughness=0.5, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes

    # Clear default
    nodes.clear()

    # Principled BSDF
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic

    return mat

# Pattern 4: UV Mapping (Auto)
def auto_uv_unwrap(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.uv.unwrap(method='ANGLE_BASED')

# Pattern 5: Rigging (Armature)
def create_armature(name, bones_data):
    armature = bpy.data.armatures.new(name)
    obj = bpy.data.objects.new(name, armature)
    bpy.context.collection.objects.link(obj)

    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')

    for bone_name, parent, head, tail in bones_data:
        bone = armature.edit_bones.new(bone_name)
        bone.head = head
        bone.tail = tail
        if parent:
            bone.parent = armature.edit_bones.get(parent)

    bpy.ops.object.mode_set(mode='OBJECT')
    return obj

# Pattern 6: Animation Keyframes
def set_keyframe(obj, prop, frame, value):
    obj[prop] = value
    obj.keyframe_insert(data_path=prop, frame=frame)
```

### Task Types

| Task | Haiku? | Sonnet? | Opus? |
|------|--------|---------|-------|
| Fix shader | ✅ | - | - |
| Texture generation | ✅ | - | - |
| UV unwrapping | ✅ | - | - |
| Simple mesh creation | ✅ | ✅ | - |
| Complex rigging | - | ✅ | - |
| Character model from spec | - | ✅ | ✅ |
| Multi-object scene | - | ✅ | ✅ |
| Animation system | - | - | ✅ |

### Output Format

Always request scripts to be wrapped in a Python code block:

```python
import bpy
# Generated script here
```

### Constraints

- **No external dependencies**: Only use bpy (Blender built-in)
- **Headless compatible**: Scripts must work in `blender -b` mode
- **Error handling**: Add try/except for missing objects
- **Performance**: Avoid nested loops on large meshes
- **Export**: Always include final export step (FBX/GLTF)

---

## 2. UNITY C# GENERATION

### Guidelines

- **Language**: C# (.NET Framework, .NET 6+)
- **Framework**: Unity 2022 LTS+
- **Style**: follow Unity conventions, PascalCase for classes

### Core Patterns

```csharp
// Pattern 1: MonoBehaviour Base
using UnityEngine;

public class GameController : MonoBehaviour
{
    [SerializeField] private float moveSpeed = 5f;

    private void Start()
    {
        // Initialization
    }

    private void Update()
    {
        // Per-frame logic
    }
}

// Pattern 2: Physics Integration
public class PlayerMovement : MonoBehaviour
{
    private Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    public void Move(Vector3 direction)
    {
        rb.velocity = direction * moveSpeed;
    }
}

// Pattern 3: UI System
using UnityEngine.UI;

public class HudController : MonoBehaviour
{
    [SerializeField] private Text healthText;
    [SerializeField] private Slider healthBar;

    public void UpdateHealth(float current, float max)
    {
        healthText.text = $"{current}/{max}";
        healthBar.value = current / max;
    }
}

// Pattern 4: Networking (Mirror or Netcode)
using Mirror;

public class PlayerNetworking : NetworkBehaviour
{
    [SyncVar(hook = nameof(OnHealthChanged))]
    public float health = 100f;

    private void OnHealthChanged(float oldValue, float newValue)
    {
        // Update UI based on new health
    }

    [Command]
    public void CmdTakeDamage(float damage)
    {
        health -= damage;
    }
}

// Pattern 5: Scriptable Objects (Config)
[CreateAssetMenu(fileName = "GameConfig", menuName = "Game/Config")]
public class GameConfig : ScriptableObject
{
    public float playerSpeed = 5f;
    public int maxHealth = 100;
    public float gravity = 9.81f;
}

// Pattern 6: Event System
using UnityEngine.Events;

public class GameEvents : MonoBehaviour
{
    public UnityEvent<float> OnHealthChanged = new();
    public UnityEvent<bool> OnGameStateChanged = new();

    public static GameEvents Instance { get; private set; }

    private void Awake()
    {
        if (Instance != null)
            Destroy(gameObject);
        else
            Instance = this;
    }
}
```

### Task Types

| Task | Haiku? | Sonnet? | Opus? |
|------|--------|---------|-------|
| Fix script compile error | ✅ | - | - |
| Add UI button logic | ✅ | - | - |
| Player movement controller | - | ✅ | - |
| Simple physics integration | - | ✅ | - |
| Multiplayer sync system | - | - | ✅ |
| Complex game state manager | - | ✅ | ✅ |
| Networking architecture | - | - | ✅ |
| Physics-based puzzle system | - | ✅ | - |

### Output Format

Always request scripts as complete C# files:

```csharp
using UnityEngine;

public class MyScript : MonoBehaviour
{
    // Implementation
}
```

### Constraints

- **Unity versions**: Target 2022 LTS (v2022.3+)
- **Serialization**: Use [SerializeField] for inspector access
- **Performance**: Avoid O(n²) algorithms, cache GetComponent calls
- **Networking**: Use Mirror or Netcode for Games
- **Dependencies**: List required packages in manifest.json format
- **Compatibility**: Test with Mac/Windows/Linux

---

## 3. GAME DEVELOPMENT WORKFLOW

### Asset Pipeline

```
Specification (JSON)
    ↓
Claude generates Blender script
    ↓
Blender generates .blend
    ↓
Export to FBX/GLTF
    ↓
Unity imports asset
    ↓
C# scripts configure material/physics
    ↓
Playtest & iterate
```

### Example: Character Creation

**Input JSON**:
```json
{
  "type": "character",
  "name": "Hero",
  "height": 2.0,
  "style": "humanoid-warrior",
  "materials": ["skin", "armor", "leather"],
  "rigging": "bipedal-humanoid",
  "animations": ["idle", "walk", "attack", "die"]
}
```

**Claude generates**:
1. Blender Python script (mesh + rig)
2. C# controller script
3. Animation definitions
4. UI integration

---

## 4. PERFORMANCE BUDGETS

### Memory
- Character meshes: < 50K vertices
- Scenes: < 1M vertices total
- Textures: < 2GB VRAM

### Frame Rate
- Target: 60 FPS (120 FPS for VR)
- Physics: max 30 substeps
- Batching: combine meshes < 100 draw calls

### Build Size
- Game executable: < 100MB
- Assets: < 500MB
- Total: < 1GB

---

## 5. CONTEXT LOADING FOR GAME DEV TASKS

### For Blender Tasks
Load:
- `game-dev-CLAUDE.md` (this file)
- `asset-pipeline.json` (asset specs)
- `blender-version.txt` (target Blender version)
- Relevant code snippet from previous scripts (if modifying)

**Token budget**: 1500-2500 tokens

### For Unity Tasks
Load:
- `game-dev-CLAUDE.md` (this file)
- `unity-project.json` (project structure)
- `gameplay-spec.json` (game mechanics)
- Relevant .cs file (if modifying)
- Networking architecture (if multiplayer)

**Token budget**: 2000-3500 tokens

---

## 6. CLAUDE MODEL SELECTION FOR GAMES

| Task | Model | Cost | Reason |
|------|-------|------|--------|
| Fix compile error | Haiku | $0.003 | Simple logic |
| Add simple behavior | Haiku | $0.005 | Well-defined pattern |
| Implement game mechanic | Sonnet | $0.015 | Context-dependent |
| Optimize frame rate | Sonnet | $0.020 | Performance analysis |
| Architecture (networked) | Opus | $0.050+ | Complex interactions |
| Physics-based puzzle | Sonnet | $0.025 | Complex logic |

---

## 7. RED FLAGS (Game Dev)

🚨 **Don't use Opus for:**
- Single mesh generation → Use Haiku
- UI button logic → Use Haiku
- Simple animation → Use Haiku

🚨 **Don't send to Claude:**
- Entire Unity project folder
- All Blender source files
- Compiled assets (.dll, .so, .dylib)
- Large binary files

✅ **Do send to Claude:**
- Specific .cs file you're modifying
- Asset specification (JSON)
- Error message + 2-3 context lines
- Architecture diagram (ASCII)

---

## 8. INTEGRATION WITH AI AGGREGATOR

When used with `ai-aggregator`:

```json
{
  "task_type": "game_dev",
  "sub_type": "unity_scripting",
  "context": {
    "engine": "Unity",
    "version": "2022.3 LTS",
    "target_platform": ["Windows", "macOS"],
    "script_type": "MonoBehaviour"
  },
  "model_policy": {
    "preferred": "claude-3-5-sonnet",
    "fallbacks": ["claude-3-haiku", "claude-3-opus"],
    "temperature": 0.1
  }
}
```

---

## 9. EXAMPLE: Generate Player Controller

**Prompt to Claude:**

```
## Task: Generate Unity Player Movement Controller

## Context
game-dev-CLAUDE.md (this file)
Unity 2022.3 LTS
Rigidbody-based physics

## Requirements
1. Smooth WASD movement
2. Jump with space (gravity)
3. Clamp speed at max 10 m/s
4. Animations: idle, walk, jump
5. Input buffering for jump

## Output Format
C# MonoBehaviour class, production-ready
```

**Claude Output**:
```csharp
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [SerializeField] private float moveSpeed = 7f;
    [SerializeField] private float jumpForce = 5f;
    [SerializeField] private float groundDrag = 5f;
    [SerializeField] private LayerMask groundLayer;

    private Rigidbody rb;
    private Animator anim;
    private bool isGrounded;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
        anim = GetComponent<Animator>();
    }

    private void Update()
    {
        CheckGround();
        HandleInput();
        ClampSpeed();
        UpdateAnimations();
    }

    private void CheckGround()
    {
        isGrounded = Physics.Raycast(transform.position, Vector3.down, 0.2f, groundLayer);
    }

    private void HandleInput()
    {
        float moveX = Input.GetAxis("Horizontal");
        float moveZ = Input.GetAxis("Vertical");

        Vector3 moveDir = transform.forward * moveZ + transform.right * moveX;
        rb.velocity = new Vector3(moveDir.x * moveSpeed, rb.velocity.y, moveDir.z * moveSpeed);

        rb.drag = isGrounded ? groundDrag : 0;

        if (Input.GetKeyDown(KeyCode.Space) && isGrounded)
        {
            rb.velocity = new Vector3(rb.velocity.x, 0, rb.velocity.z);
            rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
        }
    }

    private void ClampSpeed()
    {
        float horizontalSpeed = new Vector3(rb.velocity.x, 0, rb.velocity.z).magnitude;
        if (horizontalSpeed > moveSpeed)
        {
            Vector3 limitedVelocity = rb.velocity.normalized * moveSpeed;
            rb.velocity = new Vector3(limitedVelocity.x, rb.velocity.y, limitedVelocity.z);
        }
    }

    private void UpdateAnimations()
    {
        float moveSpeed = new Vector3(rb.velocity.x, 0, rb.velocity.z).magnitude;
        anim.SetFloat("Speed", moveSpeed);
        anim.SetBool("IsGrounded", isGrounded);
    }
}
```

---

## Summary

| Aspect | Value |
|--------|-------|
| **Primary Models** | Haiku (scripts), Sonnet (logic), Opus (architecture) |
| **Languages** | Python (Blender), C# (Unity) |
| **Task Distribution** | 50% Haiku, 40% Sonnet, 10% Opus |
| **Context Budget** | 1.5K-3.5K tokens per task |
| **Output Format** | Code blocks (Python) or C# classes (Unity) |
| **Performance Target** | 60 FPS, < 100 draw calls |

---

**Last updated**: 2026-04-16
